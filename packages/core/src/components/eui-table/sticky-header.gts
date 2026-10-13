import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import { BOX_SIZING, TABLE_RESET } from '../../-private/table.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  EUI_TABLE_CSS_CONTAINER_NAME,
  euiContainerCSS,
  euiTableStickyHeaderStyles,
  euiTableStyles
} from '../../utils/eui/styles.generated.ts';

/** What the sticky header needs from its `EuiTable`. */
export interface StickyHeaderHost {
  readonly stickyHeaderRow?: HTMLTableRowElement;
  /** The sticky copy's scrolling container (synced with the table's wrapper). */
  stickyContainer?: HTMLElement;
  /** The sticky copy's `<table>` (its min width follows the table's). */
  stickyTable?: HTMLTableElement;
  /** The table's `<table>`. */
  tableElement?: HTMLTableElement;
}

export interface EuiTableStickyHeaderSignature {
  Args: {
    table: StickyHeaderHost;
    compressed?: boolean;
    scrollableInline?: boolean;
  };
}

const CONTAINER = euiContainerCSS('normal', EUI_TABLE_CSS_CONTAINER_NAME, true);

/**
 * @private The sticky copy of an `EuiTable`'s header (upstream
 * `EuiTableStickyHeader`). Taken out of the document flow (zero height),
 * it sticks to the top of the viewport over the table's own header; the
 * header cells render their copies into its row. Hidden from assistive
 * technologies: the table's own header stays the accessible one.
 */
export default class EuiTableStickyHeader extends Component<EuiTableStickyHeaderSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const original = useEuiBorealisStyles(context, euiTableStyles);
    const styles = useEuiBorealisStyles(context, euiTableStickyHeaderStyles);
    const { compressed, scrollableInline } = this.args;
    return {
      wrapper: euiClass(context, BOX_SIZING, styles.wrapper),
      container: euiClass(context, BOX_SIZING, CONTAINER, styles.innerWrapper),
      // Same order as upstream; the layout is always fixed since every
      // column width comes from the table (the sticky header is not shown
      // in the cards layout, so `isResponsive` is false here).
      table: euiClass(
        context,
        TABLE_RESET,
        original.euiTable,
        scrollableInline ? original.euiTableScrollableInline : undefined,
        !compressed ? original.uncompressed : undefined,
        compressed ? original.compressed : undefined,
        original.layout.fixed,
        original.hasBackground,
        styles.table
      ),
      header: euiClass(context, styles.header)
    };
  }

  captureContainer = modifier((element: HTMLElement) => {
    const { table } = this.args;
    table.stickyContainer = element;
    const scroller = table.tableElement?.parentElement;
    if (scroller) element.scrollLeft = scroller.scrollLeft;
    return () => {
      if (table.stickyContainer === element) table.stickyContainer = undefined;
    };
  });

  captureTable = modifier(
    (element: HTMLTableElement, [scrollableInline]: [boolean | undefined]) => {
      const { table } = this.args;
      table.stickyTable = element;
      // upstream's initial width sync (inline scrolling only)
      if (scrollableInline && table.tableElement) {
        element.style.minWidth = `${table.tableElement.getBoundingClientRect().width}px`;
      } else {
        element.style.removeProperty('min-width');
      }
      return () => {
        if (table.stickyTable === element) table.stickyTable = undefined;
      };
    }
  );

  /** Puts the row the header cells render their copies into. */
  attachRow = modifier(
    (element: HTMLElement, [row]: [HTMLTableRowElement | undefined]) => {
      if (!row) return;
      element.appendChild(row);
      return () => {
        if (row.parentNode === element) row.remove();
      };
    }
  );

  <template>
    <div class={{this.classes.wrapper}} aria-hidden="true">
      <div
        class="euiTableStickyHeader__container {{this.classes.container}}"
        {{this.captureContainer}}
      >
        <table
          class="euiTableStickyHeader {{this.classes.table}}"
          {{this.captureTable @scrollableInline}}
        >
          <thead
            class={{this.classes.header}}
            {{this.attachRow @table.stickyHeaderRow}}
          ></thead>
        </table>
      </div>
    </div>
  </template>
}
