import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { schedule } from '@ember/runloop';
import { htmlSafe } from '@ember/template';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridBodyStyles } from '../../utils/eui/styles.generated.ts';
import EuiDataGridBodyBase from './body-base.ts';
import EuiDataGridCell from './cell.gts';
import EuiDataGridFooterRow from './footer-row.gts';
import EuiDataGridHeaderRow from './header-row.gts';

import type { TOC } from '@ember/component/template-only';
import type EuiDataGrid from '../eui-data-grid.gts';
import type { EuiDataGridSignature } from '../eui-data-grid.gts';
import type { EuiDataGridBodyBaseArgs } from './body-base.ts';
import type { EuiDataGridHeaderRowSignature } from './header-row.gts';
import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridCellValueSignature,
  EuiDataGridColumn,
  EuiDataGridControlColumn
} from '../../utils/data-grid/types.ts';
import type { ComponentLike } from '@glint/template';

type CellPopoverBlock = EuiDataGridSignature['Blocks']['cellPopover'];

/**
 * The `Cell` a custom grid body renders: the grid cell at `@colIndex` /
 * `@visibleRowIndex`. Its content comes from the grid's `@renderCellValue`
 * (or `@renderCellValue` here); the grid's `<:cell>` block can't reach
 * a custom body, so give block content to the `Cell` itself.
 */
export interface EuiDataGridCustomBodyCellSignature {
  Element: HTMLDivElement;
  Args: {
    /** Visible column index (including leading control columns). */
    colIndex: number;
    /** Visible row index on the current page (0 is the page's first row). */
    visibleRowIndex: number;
    /** Overrides the column's `isExpandable`. */
    isExpandable?: boolean;
    /** Overrides the grid's `@renderCellValue` (and control columns' `rowCellRender`). */
    renderCellValue?: ComponentLike<EuiDataGridCellValueSignature>;
  };
  Blocks: {
    /** Cell content of data columns (like the grid's `<:cell>` block). */
    default: [EuiDataGridCellValueElementProps];
    /** Cell content of control columns without `rowCellRender`. */
    controlCell: [EuiDataGridCellValueElementProps];
    /** Expansion popover content (like the grid's `<:cellPopover>` block). */
    cellPopover: CellPopoverBlock;
  };
}

export interface EuiDataGridCustomFooterRowSignature {
  Element: HTMLDivElement;
  Blocks: Pick<
    EuiDataGridSignature['Blocks'],
    'footerCell' | 'controlFooterCell' | 'cellPopover'
  >;
}

/** Attributes, classes, styles and `on*` listeners for the custom body's wrapping element. */
export type EuiDataGridSetCustomGridBodyProps = {
  className?: string;
  style?: Record<string, string | number | undefined>;
  'data-test-subj'?: string;
  [attributeOrListener: string]: unknown;
};

/** What `@renderCustomGridBody` / the `<:customGridBody>` block receive. */
export interface EuiDataGridCustomBodyProps {
  /**
   * The grid cell component: pass a valid `@colIndex` and `@visibleRowIndex`,
   * and optionally `@isExpandable` / `@renderCellValue` overrides.
   */
  Cell: ComponentLike<EuiDataGridCustomBodyCellSignature>;
  /** The visible columns (leading control, data and trailing control columns) in display order. */
  visibleColumns: Array<EuiDataGridColumn | EuiDataGridControlColumn>;
  /** The page's rows: slice your data with `startRow`/`endRow` to follow pagination. */
  visibleRowData: { startRow: number; endRow: number; visibleRowCount: number };
  /** Sets attributes, `className`, `style` and `on*` listeners on the body's wrapping element. */
  setCustomGridBodyProps: (props: EuiDataGridSetCustomGridBodyProps) => void;
  /** Width of the grid, a layout utility. */
  gridWidth: number;
  /** The header row to render (undefined when `@headerVisibility` is false). */
  headerRow?: ComponentLike<{
    Element: HTMLDivElement;
    Blocks: EuiDataGridHeaderRowSignature['Blocks'];
  }>;
  /** The footer row to render (undefined without footer cells). */
  footerRow?: ComponentLike<EuiDataGridCustomFooterRowSignature>;
}

export interface EuiDataGridCustomBodySignature {
  Args: EuiDataGridBodyBaseArgs & {
    renderCustomGridBody?: ComponentLike<{ Args: EuiDataGridCustomBodyProps }>;
  };
  Blocks: {
    customGridBody: [EuiDataGridCustomBodyProps];
  };
}

/** `Cell` of a custom grid body: forwards to `EuiDataGridCell`. */
const EuiDataGridCustomBodyCell: TOC<
  EuiDataGridCustomBodyCellSignature & {
    Args: { grid: EuiDataGrid; body: EuiDataGridCustomBody };
  }
> = <template>
    <EuiDataGridCell
      @grid={{@grid}}
      @body={{@body}}
      @colIndex={{@colIndex}}
      @visibleRowIndex={{@visibleRowIndex}}
      @isExpandable={{@isExpandable}}
      @renderCellValue={{@renderCellValue}}
      @hasCellPopoverBlock={{has-block "cellPopover"}}
      ...attributes
    >
      <:cell as |cell|>{{yield cell}}</:cell>
      <:controlCell as |cell|>{{yield cell to="controlCell"}}</:controlCell>
      <:cellPopover as |popover|>{{yield popover to="cellPopover"}}</:cellPopover>
    </EuiDataGridCell>
  </template>;

/** `footerRow` of a custom grid body. */
const EuiDataGridCustomFooterRow: TOC<
  EuiDataGridCustomFooterRowSignature & {
    Args: { grid: EuiDataGrid; body: EuiDataGridCustomBody };
  }
> = <template>
    <EuiDataGridFooterRow
      @grid={{@grid}}
      @body={{@body}}
      @hasCellPopoverBlock={{has-block "cellPopover"}}
      ...attributes
    >
      <:footerCell as |cell|>{{yield cell to="footerCell"}}</:footerCell>
      <:controlFooterCell as |cell|>{{yield cell to="controlFooterCell"}}</:controlFooterCell>
      <:cellPopover as |popover|>{{yield popover to="cellPopover"}}</:cellPopover>
    </EuiDataGridFooterRow>
  </template>;

const toKebab = (property: string) =>
  property.startsWith('--')
    ? property
    : property.replace(/[A-Z]/g, (match) => `-${match.toLowerCase()}`);

/**
 * Port of upstream `EuiDataGridBodyCustomRender`: hands the consumer's
 * renderer the grid's `Cell`, header and footer rows, visible columns and
 * rows, without virtualization.
 */
export default class EuiDataGridCustomBody extends EuiDataGridBodyBase<EuiDataGridCustomBodySignature> {
  readonly isVirtualized = false;

  get availableWidth(): number {
    return this.grid.gridWidth;
  }

  /* custom props ------------------------------------------------------- */

  @tracked customGridBodyProps: EuiDataGridSetCustomGridBodyProps = {};

  /** May be called during render; the update is applied after rendering. */
  @action
  setCustomGridBodyProps(props: EuiDataGridSetCustomGridBodyProps): void {
    schedule('afterRender', () => {
      if (!this.isDestroying) this.customGridBodyProps = props;
    });
  }

  get customStyle() {
    const style = this.customGridBodyProps.style;
    if (!style) return undefined;
    return htmlSafe(
      Object.entries(style)
        .filter(([, value]) => value != null && value !== '')
        .map(([key, value]) => `${toKebab(key)}:${typeof value === 'number' ? `${value}px` : value}`)
        .join(';')
    );
  }

  /** Attributes and `on*` listeners from `setCustomGridBodyProps`. */
  customAttributes = modifier(
    (element: HTMLElement, [props]: [EuiDataGridSetCustomGridBodyProps]) => {
      const names: string[] = [];
      const listeners: Array<[string, EventListener]> = [];
      for (const [name, value] of Object.entries(props)) {
        if (name === 'className' || name === 'style') continue;
        if (typeof value === 'function' && /^on[A-Z]/.test(name)) {
          const type = name.slice(2).toLowerCase();
          element.addEventListener(type, value as EventListener);
          listeners.push([type, value as EventListener]);
          continue;
        }
        if (value == null || value === false || typeof value === 'function') continue;
        element.setAttribute(name, String(value as string | number | boolean));
        names.push(name);
      }
      return () => {
        names.forEach((name) => element.removeAttribute(name));
        listeners.forEach(([type, listener]) => element.removeEventListener(type, listener));
      };
    }
  );

  /* classes ------------------------------------------------------------ */

  @cached
  get bodyClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridBodyStyles);
    return euiClass(context, styles.euiDataGridBody, styles.customRender);
  }

  get classes(): string {
    return ['euiDataGrid__customRenderBody', this.bodyClass, this.customGridBodyProps.className]
      .filter(Boolean)
      .join(' ');
  }

  /* renderer props ----------------------------------------------------- */

  @cached
  get visibleColumns(): Array<EuiDataGridColumn | EuiDataGridControlColumn> {
    const { leadingControlColumns, columns, trailingControlColumns } = this.grid;
    return [...leadingControlColumns, ...columns, ...trailingControlColumns];
  }

  get visibleRowData() {
    return this.grid.visibleRows;
  }

  <template>
    <div
      class={{this.classes}}
      style={{this.customStyle}}
      {{this.customAttributes this.customGridBodyProps}}
    >
      {{#let
        (hash
          Cell=(component EuiDataGridCustomBodyCell grid=@grid body=this)
          visibleColumns=this.visibleColumns
          visibleRowData=this.visibleRowData
          setCustomGridBodyProps=this.setCustomGridBodyProps
          gridWidth=@grid.gridWidth
          headerRow=(if
            @grid.showHeader (component EuiDataGridHeaderRow grid=@grid body=this)
          )
          footerRow=(if
            this.hasFooter (component EuiDataGridCustomFooterRow grid=@grid body=this)
          )
        )
        as |props|
      }}
        {{#if @renderCustomGridBody}}
          {{#let @renderCustomGridBody as |Renderer|}}
            <Renderer
              @Cell={{props.Cell}}
              @visibleColumns={{props.visibleColumns}}
              @visibleRowData={{props.visibleRowData}}
              @setCustomGridBodyProps={{props.setCustomGridBodyProps}}
              @gridWidth={{props.gridWidth}}
              @headerRow={{props.headerRow}}
              @footerRow={{props.footerRow}}
            />
          {{/let}}
        {{else}}
          {{yield props to="customGridBody"}}
        {{/if}}
      {{/let}}
    </div>
  </template>
}
