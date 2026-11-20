/** Clicks: on cells, control cells, and double clicks (V03C-DESIGN.md 3.2). */
import { action } from '@ember/object';

import { isReadOnly, valueOf } from '../../core/index.ts';

import type EuiSheet from '../../components/eui-sheet.gts';

export default class SheetClicks<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /**
   * Airtable-style clicks: the first click selects (the grid focuses the
   * cell); a click on the selected cell edits; the type's opener button
   * opens the editor in one click; a type with `onCellClick` (the checkbox)
   * saves on any click. Before those: the row-number column (checkbox,
   * expand icon), a column header (selects the column) and the add row.
   */
  @action
  onClick(event: MouseEvent): void {
    if (this.sheet.frozen.pressing) {
      this.sheet.frozen.pressing = false;
      const focused = document.activeElement;
      const frozen =
        (this.sheet.dom.rowNumberCell(focused) &&
          this.sheet.frozen.frozenCount) ||
        (this.sheet.dom.dataCell(focused) &&
          this.sheet.dom.cursor(this.sheet.dom.dataCell(focused)!).col <
            this.sheet.frozen.frozenCount);
      if (frozen) this.sheet.frozen.keepFrozenScroll();
      else this.sheet.frozen.scrollLeftBeforeFocus = null;
    }
    const pressOnFocusedCell = this.sheet.drag.pressOnFocusedCell;
    this.sheet.drag.pressOnFocusedCell = false;
    this.sheet.focus.keepRangeOnFocus = false;
    if (this.sheet.drag.suppressClick) {
      this.sheet.drag.suppressClick = false;
      return;
    }
    const target = event.target as Element;
    if (this.sheet.dom.isInMenu(target)) return;
    // a header's chevron or title (V03 8.3), on a data or row-number cell
    if (
      this.sheet.rows.isGrouped &&
      this.sheet.groupHeaders.onGroupToggleClick(target)
    )
      return;
    if (this.onControlClick(event, target)) return;
    if (event.shiftKey || this.sheet.edit.editing) return;
    const cell = this.sheet.dom.dataCell(target);
    if (!cell) return;
    const pos = this.sheet.dom.cursor(cell);
    if (this.sheet.rows.isAddRow(pos.row)) {
      this.sheet.records.appendRecord(pos.row);
      return;
    }
    const record = this.sheet.rows.recordAt(pos.row);
    const field = this.sheet.fields.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const type = this.sheet.fields.typeOf(field);
    // a click on the link text opens it (first click, no edit)
    if (target.closest('[data-eui-sheet-link]')) {
      if (
        this.sheet.cells.openLink(
          this.sheet.cells.linkOf(type, field, valueOf(record, field.id))
        )
      ) {
        return;
      }
    }
    // a star click is the cell's own (`@onCommit`): no edit
    if (target.closest('[data-eui-sheet-star]')) return;
    if (target.closest('[data-eui-sheet-opener]')) {
      if (this.sheet.cells.canEdit(pos) && !this.sheet.edit.editInRecord(pos)) {
        this.sheet.edit.startEdit(pos, cell, null);
      }
      return;
    }
    if (type.onCellClick) {
      if (isReadOnly(this.sheet.context, field, record)) return;
      const result = type.onCellClick(
        valueOf(record, field.id) as never,
        field,
        record
      );
      if (result)
        this.sheet.cells.commitCellValue(pos.row, pos.col, result.value);
      return;
    }
    if (
      pressOnFocusedCell &&
      this.sheet.cells.canEdit(pos) &&
      !this.sheet.edit.editInRecord(pos)
    ) {
      this.sheet.edit.startEdit(pos, cell, null);
    }
  }

  /** Clicks on the row-number column and the column headers; true when handled. */
  onControlClick(event: MouseEvent, target: Element): boolean {
    // the "+" header (V03 6.3)
    if (this.sheet.dom.addFieldHeader(target)) {
      this.sheet.fieldEditor.addField();
      return true;
    }
    if (target.closest('[data-eui-sheet-row-check-all]')) {
      this.sheet.checked.toggleAllChecked();
      return true;
    }
    const rowCell = this.sheet.dom.rowNumberCell(target);
    if (rowCell) {
      const row = this.sheet.dom.rowIndexOf(rowCell);
      if (this.sheet.rows.isAddRow(row)) {
        this.sheet.records.appendRecord(row);
      } else if (target.closest('[data-eui-sheet-row-check]')) {
        this.sheet.checked.toggleChecked(row, event.shiftKey);
      } else if (target.closest('[data-eui-sheet-row-expand]')) {
        const record = this.sheet.rows.recordAt(row);
        if (record !== undefined) {
          const recordId = this.sheet.args.getRecordId(record);
          this.sheet.expanded.expandRecord(recordId, {
            recordId,
            fieldId: null
          });
        }
      }
      return true;
    }
    // a header's title (not its actions button or resizer) selects the column
    const header = this.sheet.dom.headerCell(target);
    if (header && target.closest('.euiDataGridHeaderCell__content')) {
      const col =
        Number(header.dataset['gridcellColumnIndex']) - this.sheet.colOffset;
      if (col >= 0 && col < this.sheet.fields.visibleFields.length) {
        this.sheet.selection.selectColumns(col, event.shiftKey);
      }
      return true;
    }
    return false;
  }

  @action
  onDoubleClick(event: MouseEvent): void {
    // the double-click's second click already opened the editor
    if (this.sheet.edit.editing) return;
    const cell = this.sheet.dom.dataCell(event.target);
    if (!cell) return;
    const pos = this.sheet.dom.cursor(cell);
    if (this.sheet.cells.canEdit(pos) && !this.sheet.edit.editInRecord(pos)) {
      this.sheet.edit.startEdit(pos, cell, null);
    }
  }
}
