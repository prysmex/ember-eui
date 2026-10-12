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

import type { TableAlignment } from '../-private/table.ts';

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
  };
  Blocks: {
    /** The content (truncated to one line, as upstream). */
    default: [];
  };
}

export default class EuiTableFooterCell extends Component<EuiTableFooterCellSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableHeaderFooterCellStyles);
    return euiClass(
      context,
      CELL_RESET,
      styles.euiTableFooterCell.euiTableFooterCell,
      tableContext(this).hasBackground
        ? styles.euiTableFooterCell.hasBackground
        : undefined
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
      ...attributes
    >
      <div class="euiTableCellContent {{this.contentClass}}">
        <span class="euiTableCellContent__text">{{yield}}</span>
      </div>
    </td>
  </template>
}
