/**
 * EuiSheet spike (DESIGN.md, section 5.6): the grid's `@renderCellValue`.
 * Shows the formatted value and draws the selection with `setCellProps`.
 */
import Component from '@glimmer/component';

import type { EuiDataGridCellValueElementProps } from '#src/utils/data-grid/types.ts';
import type EuiSheet from './eui-sheet.gts';

interface SheetCellContext {
  sheet: EuiSheet<object>;
}

export default class SheetCellValue extends Component<{
  Args: EuiDataGridCellValueElementProps;
}> {
  get sheet(): EuiSheet<object> {
    return (this.args.cellContext as unknown as SheetCellContext).sheet;
  }

  // Reads the sheet's tracked anchor/head, so it re-runs on every selection
  // change and when the cell is re-created after scrolling. setCellProps
  // only schedules (applied after render), so calling it here is allowed.
  get selection(): string {
    const selected = this.sheet.isSelected(
      this.args.rowIndex,
      this.args.colIndex
    );
    this.args.setCellProps(
      selected
        ? {
            className: 'euiSheetSpike__cell--selected',
            'aria-selected': 'true'
          }
        : {}
    );
    return '';
  }

  get text(): string {
    return this.sheet.displayValue(this.args.rowIndex, this.args.columnId);
  }

  <template>{{this.selection}}{{this.text}}</template>
}
