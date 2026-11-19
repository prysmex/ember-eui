/**
 * The summary bar (V02-DESIGN.md 6.6): the grid's footer row shows the
 * owner's `@summary` text of each field, and `@summary['']` under the
 * row numbers. Plain text: footer cells take no edits and no range (the
 * sheet's `dataCell` skips them). Frozen like the cells above them.
 */
import Component from '@glimmer/component';

import type EuiSheet from '../components/eui-sheet.gts';
import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridSetCellProps
} from '@ember-eui/core/utils/data-grid/types';

interface SheetCellContext {
  sheet: EuiSheet<object>;
}

/** `@renderFooterCellValue`: a data column's summary. */
export default class SheetFooterCell extends Component<{
  Args: EuiDataGridCellValueElementProps;
}> {
  get sheet(): EuiSheet<object> {
    return (this.args.cellContext as unknown as SheetCellContext).sheet;
  }

  get text(): string {
    return this.sheet.args.summary?.[this.args.columnId] ?? '';
  }

  // as SheetCell: setCellProps only schedules, so calling it in render is allowed
  get cellProps(): string {
    this.args.setCellProps(footerProps(this.sheet, this.args.colIndex));
    return '';
  }

  <template>
    {{this.cellProps}}
    <span
      class="euiSheet__summary"
      data-test-subj="euiSheetSummary"
    >{{this.text}}</span>
  </template>
}

/** `<:controlFooterCell>`: the row-number column's summary, `@summary['']`. */
export class SheetControlFooterCell extends Component<{
  Args: {
    sheet: EuiSheet<any>;
    setCellProps: (props: EuiDataGridSetCellProps) => void;
  };
}> {
  get text(): string {
    return this.args.sheet.args.summary?.[''] ?? '';
  }

  get cellProps(): string {
    this.args.setCellProps(footerProps(this.args.sheet, 0));
    return '';
  }

  <template>
    {{this.cellProps}}
    <span
      class="euiSheet__summary"
      data-test-subj="euiSheetSummary"
    >{{this.text}}</span>
  </template>
}

/** Footer cells are flex items, not absolute: frozen ones are sticky without the float (9.2). */
function footerProps(
  sheet: EuiSheet<any>,
  colIndex: number
): EuiDataGridSetCellProps {
  const frozen = sheet.frozenCellProps(colIndex, true);
  return frozen ? { className: frozen.className, style: frozen.style } : {};
}
