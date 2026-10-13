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
  euiTableHeaderFooterCellStyles
} from '../utils/eui/styles.generated.ts';
import { euiTableStickyCellStyles } from '../utils/eui/table.ts';

import type { TableAlignment } from '../-private/table.ts';
import type { EuiTableStickyCellOptions } from '../utils/eui/table.ts';

/** A cell of an `EuiTableFooter`, e.g. a column's total. */
export interface EuiTableFooterCellSignature {
  Element: HTMLTableCellElement;
  Args: {
    /** `'left'`, `'right'` (numbers) or `'center'`. Defaults to `'left'`. */
    align?: TableAlignment;
    /** Width, e.g. `100` (px) or `'20%'`. */
    width?: number | string;
    /** Min width, e.g. `100` (px). */
    minWidth?: number | string;
    /** Max width, e.g. `'30%'`. */
    maxWidth?: number | string;
    /**
     * Sticks the cell to a side of the table (`{ side: 'start' | 'end' }`)
     * while it scrolls inline; only for the first or last column, and not
     * in the cards layout. Upstream beta.
     */
    sticky?: EuiTableStickyCellOptions;
  };
  Blocks: {
    /** The content (truncated to one line, as upstream). */
    default: [];
  };
}

export default class EuiTableFooterCell extends Component<EuiTableFooterCellSignature> {
  /** Sticky cells are not applied in the cards layout (upstream). */
  get stickySide(): 'start' | 'end' | undefined {
    return tableContext(this).isResponsive ? undefined : this.args.sticky?.side;
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableHeaderFooterCellStyles);
    const side = this.stickySide;
    const sticky = side
      ? useEuiBorealisStyles(context, euiTableStickyCellStyles)
      : undefined;
    return euiClass(
      context,
      CELL_RESET,
      styles.euiTableFooterCell.euiTableFooterCell,
      tableContext(this).hasBackground
        ? styles.euiTableFooterCell.hasBackground
        : undefined,
      sticky?.root,
      side ? sticky?.side[side] : undefined
    );
  }

  @cached
  get contentClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableCellContentStyles);
    return euiClass(
      context,
      BOX_SIZING,
      ...cellContentStyles(styles, {
        align: this.args.align,
        truncateText: true,
        isResponsive: tableContext(this).isResponsive
      })
    );
  }

  @cached
  get style() {
    return widthStyle(this.args.width, this.args.minWidth, this.args.maxWidth);
  }

  <template>
    <td
      class="euiTableFooterCell {{this.classes}}"
      style={{this.style}}
      data-sticky={{this.stickySide}}
      ...attributes
    >
      <div class="euiTableCellContent {{this.contentClass}}">
        <span class="euiTableCellContent__text">{{yield}}</span>
      </div>
    </td>
  </template>
}
