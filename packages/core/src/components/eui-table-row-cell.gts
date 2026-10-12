import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import {
  BOX_SIZING,
  CELL_RESET,
  cellContentStyles,
  tableContext,
  widthStyle
} from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiTableCellContentStyles,
  euiTableRowCellStyles
} from '../utils/eui/styles.generated.ts';

import type { TableAlignment, TableMobileOptions } from '../-private/table.ts';
import type { CSSObject } from '@emotion/css/create-instance';

/** A cell of an `EuiTableRow`. */
export interface EuiTableRowCellSignature {
  Element: HTMLTableCellElement;
  Args: {
    /** `'left'`, `'right'` (numbers) or `'center'`. Defaults to `'left'`. */
    align?: TableAlignment;
    /**
     * `true` cuts long text with an ellipsis; otherwise long words break
     * (upstream default).
     */
    truncateText?: boolean;
    /**
     * The content is only text (wrapped in a span that truncates or
     * wraps). Set `false` for components. Defaults to `true`.
     */
    textOnly?: boolean;
    /** Renders a `<th scope="row">`: the row's header. */
    setScopeRow?: boolean;
    /**
     * Shows the content only while the row is hovered or the cell has
     * focus (always shown in the cards layout). Upstream's
     * `euiBasicTableAction-showOnHover`.
     */
    showOnHover?: boolean;
    /**
     * The cell holds the row's actions (`true`: icon actions in the cards
     * layout's right column; `'custom'`: other content on its own line).
     */
    hasActions?: boolean | 'custom';
    /** The cell holds the row's expand button. */
    isExpander?: boolean;
    /**
     * Vertical alignment: `'top'`, `'middle'`, `'bottom'` or `'baseline'`.
     * Defaults to `'middle'`.
     */
    valign?: 'top' | 'middle' | 'bottom' | 'baseline';
    /** Width, e.g. `100` (px) or `'20%'`. */
    width?: number | string;
    /** Min width, e.g. `100` (px). */
    minWidth?: number | string;
    /** Max width, e.g. `'30%'`. */
    maxWidth?: number | string;
    /**
     * In the cards layout: `{ show, only, header, enlarge, align,
     * truncateText, textOnly, width, minWidth, maxWidth }`. `header`
     * labels the value in the row's card; the `<:mobile>` block replaces
     * the content there.
     */
    mobileOptions?: TableMobileOptions;
  };
  Blocks: {
    /** The content. */
    default: [];
    /** Different content in the cards layout. */
    mobile: [];
  };
}

/** Ember's `@showOnHover` reveals its content on any row hover. */
const SHOW_ON_HOVER: CSSObject = {
  '.euiTableRow:hover &, &:focus-within': {
    '.euiBasicTableAction-showOnHover': { opacity: 1 }
  }
};

export default class EuiTableRowCell extends Component<EuiTableRowCellSignature> {
  get isResponsive(): boolean {
    return tableContext(this).isResponsive;
  }

  get mobile(): TableMobileOptions {
    return this.args.mobileOptions ?? {};
  }

  /** Upstream renders nothing for hidden cells. */
  get isRendered(): boolean {
    return this.isResponsive
      ? this.mobile.show !== false
      : !this.mobile.only;
  }

  get tagName(): 'th' | 'td' {
    return this.args.setScopeRow ? 'th' : 'td';
  }

  get mobileHeader(): string | undefined {
    return this.isResponsive ? this.mobile.header : undefined;
  }

  get textOnly(): boolean {
    const textOnly = this.args.textOnly ?? true;
    return this.isResponsive ? (this.mobile.textOnly ?? textOnly) : textOnly;
  }

  get truncateText(): boolean {
    const truncate = this.args.truncateText ?? false;
    return this.isResponsive ? (this.mobile.truncateText ?? truncate) : truncate;
  }

  get hasActionsOrExpander(): boolean | 'custom' {
    return this.args.hasActions || Boolean(this.args.isExpander);
  }

  /** The text span (upstream renders it for text or truncated content). */
  get wrapsContent(): boolean {
    return this.textOnly || this.truncateText || Boolean(this.args.showOnHover);
  }

  get textClass(): string {
    return [
      (this.textOnly || this.truncateText) && 'euiTableCellContent__text',
      this.args.showOnHover && 'euiBasicTableAction-showOnHover'
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get style() {
    const { width, minWidth, maxWidth, hasActions, isExpander } = this.args;
    if (!this.isResponsive) return widthStyle(width, minWidth, maxWidth);
    // In cards, actions are shifted to a right column via CSS
    if (hasActions || isExpander) return undefined;
    return widthStyle(
      this.mobile.width,
      this.mobile.minWidth,
      this.mobile.maxWidth
    );
  }

  @cached
  get cellClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableRowCellStyles);
    const { setScopeRow, isExpander, hasActions, showOnHover } = this.args;
    const valign = this.args.valign ?? 'middle';
    // Same order as upstream's `cssStyles`.
    const css = [
      CELL_RESET,
      styles.euiTableRowCell,
      setScopeRow ? styles.rowHeader : undefined,
      isExpander ? styles.isExpander : undefined,
      hasActions ? styles.hasActions : undefined,
      styles[valign],
      ...(this.isResponsive
        ? [
            styles.mobile.mobile,
            this.mobile.enlarge ? styles.mobile.enlarge : undefined,
            hasActions === 'custom' ? styles.mobile.customActions : undefined,
            hasActions === true ? styles.mobile.actions : undefined,
            isExpander ? styles.mobile.expander : undefined
          ]
        : [
            styles.desktop.desktop,
            hasActions || showOnHover ? styles.desktop.actions : undefined,
            showOnHover ? SHOW_ON_HOVER : undefined
          ])
    ];

    return [
      'euiTableRowCell',
      hasActions && 'euiTableRowCell--hasActions',
      isExpander && 'euiTableRowCell--isExpander',
      euiClass(context, ...css)
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get mobileHeaderClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableRowCellStyles);
    return euiClass(context, BOX_SIZING, styles.euiTableRowCell__mobileHeader);
  }

  @cached
  get contentClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableCellContentStyles);
    const align = this.isResponsive
      ? (this.mobile.align ?? 'left')
      : this.args.align;
    return euiClass(
      context,
      BOX_SIZING,
      ...cellContentStyles(styles, {
        align,
        truncateText: this.truncateText,
        hasActions: this.hasActionsOrExpander,
        isResponsive: this.isResponsive
      })
    );
  }

  <template>
    {{#if this.isRendered}}
      {{#let (element this.tagName) as |Cell|}}
        <Cell
          class={{this.cellClass}}
          scope={{if @setScopeRow "row"}}
          style={{this.style}}
          ...attributes
        >
          {{#if this.mobileHeader}}
            <div
              class="euiTableRowCell__mobileHeader {{this.mobileHeaderClass}}"
            >{{this.mobileHeader}}</div>
          {{/if}}
          <div class="euiTableCellContent {{this.contentClass}}">
            {{#if this.wrapsContent}}
              <span class={{this.textClass}}>
                {{~#if (useMobileBlock this.isResponsive (has-block "mobile"))~}}
                  {{yield to="mobile"}}
                {{~else~}}
                  {{yield}}
                {{~/if~}}
              </span>
            {{else if (useMobileBlock this.isResponsive (has-block "mobile"))}}
              {{yield to="mobile"}}
            {{else}}
              {{yield}}
            {{/if}}
          </div>
        </Cell>
      {{/let}}
    {{/if}}
  </template>
}

function useMobileBlock(isResponsive: boolean, hasMobileBlock: boolean): boolean {
  return isResponsive && hasMobileBlock;
}
