/** The clipboard: copy, cut and paste of ranges and rows (V03C-DESIGN.md 3.2). */
import { action } from '@ember/object';

import {
  clearRange,
  parseTsv,
  pasteMatrix,
  planPaste,
  rangeMatrix,
  tileMatrix,
  toTsv
} from '../../core/index.ts';
import { nextTempId, stop } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { PasteInsert, Range } from '../../core/index.ts';

/**
 * Writes text to the clipboard: `navigator.clipboard.writeText`, else (or
 * when it rejects) a hidden textarea and `execCommand('copy')`, appended to
 * the body, outside the grid (its document copy handlers).
 */
function writeClipboard(text: string): void {
  const fallback = () => {
    const area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.style.position = 'fixed';
    area.style.opacity = '0';
    document.body.appendChild(area);
    area.select();
    try {
      document.execCommand('copy');
    } finally {
      area.remove();
    }
  };
  const clipboard = navigator.clipboard as Clipboard | undefined;
  if (clipboard?.writeText) {
    clipboard.writeText(text).catch(fallback);
  } else {
    fallback();
  }
}

export default class SheetClipboard<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Copies the records' visible fields as TSV. */
  copyRows(records: readonly T[]): void {
    if (!records.length) return;
    writeClipboard(this.rowsTsv(records));
  }

  /** The records' visible fields as TSV, in the given order. */
  rowsTsv(records: readonly T[]): string {
    return toTsv(
      rangeMatrix(
        { ...this.sheet.context, records },
        {
          top: 0,
          left: 0,
          bottom: records.length - 1,
          right: this.sheet.fields.visibleFields.length - 1
        }
      )
    );
  }

  @action
  onCopy(event: ClipboardEvent): void {
    const target = event.target;
    if (this.sheet.edit.editing && this.sheet.dom.isInEditor(target)) return;
    if (this.sheet.checked.isCheckedRowsTarget(target)) {
      if (!event.clipboardData) return;
      event.clipboardData.setData(
        'text/plain',
        this.rowsTsv(this.sheet.checked.checkedRecords)
      );
      stop(event);
      return;
    }
    if (this.sheet.groupHeaders.isGroupHeaderTarget(target)) {
      event.clipboardData?.setData('text/plain', '');
      stop(event);
      return;
    }
    if (!this.isRangeTarget(target)) return;
    const range = this.sheet.selection.range;
    if (!range || !event.clipboardData) return;
    event.clipboardData.setData('text/plain', this.rangeTsv(range));
    // stopPropagation is required: the grid's document copy handlers
    stop(event);
    this.sheet.outline.copied = range;
  }

  /** The records of a grid range as TSV; '' when it holds none (the add row). */
  rangeTsv(range: Range): string {
    const records = this.sheet.rows.recordRange(range);
    return toTsv(records ? rangeMatrix(this.sheet.context, records) : []);
  }

  /**
   * Ctrl/Cmd+X (V02-DESIGN.md 8.4): copies the range as TSV, like copy,
   * then clears it (source 'cut'). A cut is a write of every writable cell
   * even when nothing changes, so a pending resolve there is dropped. With
   * `@readOnly` it only copies.
   */
  @action
  onCut(event: ClipboardEvent): void {
    const target = event.target;
    if (this.sheet.edit.editing && this.sheet.dom.isInEditor(target)) return;
    if (this.sheet.groupHeaders.isGroupHeaderTarget(target)) {
      event.clipboardData?.setData('text/plain', '');
      stop(event);
      return;
    }
    if (!this.isRangeTarget(target)) return;
    const range = this.sheet.selection.range;
    if (!range || !event.clipboardData) return;
    event.clipboardData.setData('text/plain', this.rangeTsv(range));
    // stopPropagation: the grid's document clipboard handlers
    stop(event);
    if (this.sheet.args.readOnly) {
      this.sheet.outline.copied = range;
      return;
    }
    const records = this.sheet.rows.recordRange(range);
    if (records) {
      this.sheet.changes.emit(
        clearRange(this.sheet.context, records, { source: 'cut' }),
        this.sheet.selection.touchedInRecords(records, true)
      );
    }
    // after the emit, which clears the mark of an older copy
    this.sheet.outline.copied = range;
  }

  @action
  onPaste(event: ClipboardEvent): void {
    if (this.sheet.args.readOnly) return;
    const target = event.target;
    if (this.sheet.edit.editing && this.sheet.dom.isInEditor(target)) return;
    if (!this.isRangeTarget(target)) return;
    const data = event.clipboardData;
    if (!data) return;
    // files on an attachment cell: uploaded to the range's first cell. A
    // spreadsheet's copy carries a picture of the cells besides its text
    // and HTML: then the text wins.
    const plain = data.getData('text/plain');
    const types = Array.from(data.types);
    if (
      data.files?.length &&
      (!plain.trim() || !types.includes('text/html')) &&
      this.sheet.selection.range &&
      this.sheet.uploads.pasteFiles(data.files)
    ) {
      stop(event);
      return;
    }
    if (!Array.from(data.types).includes('text/plain')) return;
    const range = this.sheet.selection.range;
    if (!range) return;
    // a header is never pasted over (V03 8.5); its row has no range anyway
    if (
      this.sheet.rows.isGrouped &&
      this.sheet.rows.rowKind(range.top) === 'group'
    )
      return;
    stop(event);
    const anchor = { row: range.top, col: range.left };
    const records = this.sheet.args.records;
    // a group's add row: every line is an insert into that group (V03 8.5)
    const addGroup = this.sheet.rows.addRowGroupAt(anchor.row);
    // the core's anchor: its record row, or `records.length` on an add row
    const at = {
      row:
        addGroup >= 0 ? records.length : this.sheet.rows.coreRowOf(anchor.row),
      col: anchor.col
    };
    // grouped, the lines past the records: into the add row's group, or
    // into the last record's group, with its values and `groupKey`
    const insert = this.sheet.rows.isGrouped
      ? this.pasteInsert(addGroup)
      : undefined;
    // a block that fits the selection a whole number of times fills it
    // (its records: a header or an add row inside is no line)
    const selection = this.sheet.rows.recordRange(range);
    let matrix = tileMatrix(
      parseTsv(data.getData('text/plain')),
      selection ? selection.bottom - selection.top + 1 : 1,
      range.right - range.left + 1
    );
    // without inserting, lines past the last record are dropped (5.8)
    if (!this.sheet.canInsert) {
      matrix = matrix.slice(
        0,
        Math.max(this.sheet.args.records.length - at.row, 0)
      );
      if (!matrix.length) return;
    }
    const width = Math.max(...matrix.map((line) => line.length));
    const right = Math.min(
      anchor.col + width - 1,
      this.sheet.fields.visibleFields.length - 1
    );
    // in record rows: the records written (inserted ones are not there yet)
    const pasted = {
      top: at.row,
      left: anchor.col,
      bottom: at.row + matrix.length - 1,
      right
    };
    const touched = this.sheet.selection.touchedInRecords(pasted, false);
    const options = insert ? { nextTempId, insert } : { nextTempId };
    if (this.sheet.args.onResolve) {
      // V9: the synchronous part at once, the resolved part later
      const plan = planPaste(this.sheet.context, at, matrix, options);
      const entry = this.sheet.changes.emit(plan.changeSet, touched);
      this.sheet.resolve.startResolve(plan, entry);
    } else {
      this.sheet.changes.emit(
        pasteMatrix(this.sheet.context, at, matrix, options),
        touched
      );
    }
    // no setFocusedCell: inserted rows exist only after the next render
    this.sheet.selection.anchor = anchor;
    this.sheet.selection.head = {
      row: this.pasteHeadRow(anchor.row, at.row, matrix.length, addGroup),
      col: right
    };
    this.sheet.selection.rangeKind = 'cells';
  }

  /**
   * Grouped (V03 8.5, D14): where a paste's lines past the records go. On
   * a group's add row, into that group after its last loaded record (no
   * anchor for an empty group); from a record, into the last record's
   * group, after it. Each with the group's values and `groupKey`.
   */
  pasteInsert(addGroup: number): PasteInsert | undefined {
    const model = this.sheet.rows.rowModel;
    const group = addGroup >= 0 ? addGroup : model.groupAt(model.lastRecordRow);
    const key = this.sheet.rows.groups[group]?.key;
    if (key === undefined) return undefined;
    const insert: PasteInsert = {
      values: this.sheet.groupHeaders.groupValuesOf(group),
      groupKey: key
    };
    if (addGroup >= 0) {
      const row = model.addRowOf(addGroup);
      // the group's last loaded record is the row above its add row
      const last = this.sheet.rows.recordRowAt(row - 1);
      const above = last >= 0 ? this.sheet.args.records[last] : undefined;
      insert.index = last >= 0 ? last + 1 : this.sheet.rows.coreRowOf(row);
      insert.anchor =
        above === undefined
          ? null
          : { recordId: this.sheet.args.getRecordId(above), position: 'after' };
    }
    return insert;
  }

  /**
   * The grid row of a paste's last line (the range's head): a record's
   * row, or past the last record's row for the inserted lines (they follow
   * it, in its group, once rendered). On a group's add row the inserts
   * take the add row's place and the rows after it.
   */
  pasteHeadRow(
    anchorRow: number,
    at: number,
    lines: number,
    addGroup: number
  ): number {
    if (addGroup >= 0) return anchorRow + lines - 1;
    const last = at + lines - 1;
    const count = this.sheet.args.records.length;
    if (last < count) return this.sheet.rows.gridRowOf(last);
    const lastRow = count ? this.sheet.rows.gridRowOf(count - 1) : -1;
    return lastRow + last - (count - 1);
  }

  /**
   * Whether a clipboard event is on the range: a data cell, a row number
   * while whole rows are selected, a header while whole columns are.
   */
  isRangeTarget(target: EventTarget | null): boolean {
    if (this.sheet.focus.isParked(target)) return true;
    const cell = this.sheet.dom.dataCell(target);
    if (cell) return this.sheet.dom.isClipboardTarget(target, cell);
    const rowCell = this.sheet.dom.rowNumberCell(target);
    if (rowCell) {
      return (
        this.sheet.selection.rangeKind === 'rows' &&
        this.sheet.dom.isClipboardTarget(target, rowCell)
      );
    }
    const header = this.sheet.dom.headerCell(target);
    if (header) {
      return (
        this.sheet.selection.rangeKind === 'columns' &&
        this.sheet.dom.isClipboardTarget(target, header)
      );
    }
    return false;
  }
}
