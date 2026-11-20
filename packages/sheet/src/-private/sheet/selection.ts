/** The selection: the range, its anchor and head, and what it touches (V03C-DESIGN.md 3.2). */
import { cached, tracked } from '@glimmer/tracking';
import { next } from '@ember/runloop';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { modifier } from 'ember-modifier';

import { clearRange, isReadOnly, toRange } from '../../core/index.ts';
import { headerMarkRules } from '../styles.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos, Range, RecordId } from '../../core/index.ts';
import type { SheetSelection as Selection } from '../../types.ts';
import type { RangeKind, Touched } from './types.ts';

/** What `@onSelectionChange` compares: the kind, the record ids and the field ids. */
function selectionKey(selection: Selection | null): string {
  if (!selection) return '';
  return JSON.stringify([
    selection.kind,
    selection.recordIds.map(String),
    selection.fields.map((field) => field.id)
  ]);
}

export default class SheetSelection<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Selection corners; `head` is where DOM focus is. */
  @tracked anchor: Pos | null = null;
  @tracked head: Pos | null = null;
  /** What the range covers: cells, whole rows (row numbers) or whole columns (headers). */
  @tracked rangeKind: RangeKind = 'cells';

  get range(): Range | null {
    return this.anchor && this.head ? toRange(this.anchor, this.head) : null;
  }

  /* The selection, exposed (V03 11.2) */

  /**
   * The range's records (group headers and add rows left out) and visible
   * fields; null without a range or with no record in it. A new object
   * only when the range, `@records` or the fields change.
   */
  @cached
  get current(): Selection<T> | null {
    const range = this.range;
    const records = range && this.sheet.rows.recordRange(range);
    if (!range || !records) return null;
    const fields = this.sheet.fields.visibleFields.slice(
      Math.max(range.left, 0),
      range.right + 1
    );
    if (!fields.length) return null;
    const chosen = this.sheet.args.records.slice(
      records.top,
      records.bottom + 1
    );
    return {
      kind: this.rangeKind,
      records: chosen,
      recordIds: chosen.map((record) => this.sheet.args.getRecordId(record)),
      fields,
      cellCount: chosen.length * fields.length
    };
  }

  /** The key of the selection last given to `@onSelectionChange` ('' for null). */
  reportedKey = '';
  /** A report is scheduled for the next run loop. */
  reportPending = false;

  /**
   * Re-runs when the selection changes (with `@onSelectionChange`):
   * reports it in the next run loop, after this one's render. At most one
   * report per run loop: a change the handler itself makes (it calls
   * `api.focusCell`) is reported in a later one.
   */
  reportChange = modifier(() => {
    if (!this.sheet.args.onSelectionChange) return;
    void this.current;
    if (this.reportPending) return;
    this.reportPending = true;
    next(this.report);
  });

  /** Calls `@onSelectionChange` when the kind, record ids or field ids changed since the last call. */
  report = (): void => {
    this.reportPending = false;
    if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
    const selection = this.current;
    const key = selectionKey(selection);
    if (key === this.reportedKey) return;
    this.reportedKey = key;
    this.sheet.args.onSelectionChange?.(selection);
  };

  /** A row of a `'rows'` range (its row number is drawn selected). */
  /** A cell range covers the row: its row number gets the light mark (V03 batch 1). */
  isRowMarked(row: number): boolean {
    const range = this.range;
    return (
      this.rangeKind === 'cells' &&
      !!range &&
      row >= range.top &&
      row <= range.bottom &&
      this.sheet.rows.isRecordRow(row)
    );
  }

  /** The marks of the selection's column headers (V03 batch 1; `headerMarkRules`). */
  get headerMarkCss(): string {
    const range = this.range;
    if (!range || this.rangeKind === 'rows') return '';
    if (!this.sheet.args.records.length && this.rangeKind === 'cells')
      return '';
    const indexes: number[] = [];
    for (let col = range.left; col <= range.right; col++) {
      indexes.push(col + this.sheet.colOffset);
    }
    return headerMarkRules(
      this.sheet.sheetId,
      indexes,
      this.rangeKind === 'columns' ? 'columns' : 'cells'
    );
  }

  isRowSelected(row: number): boolean {
    const range = this.range;
    return (
      this.rangeKind === 'rows' &&
      !!range &&
      row >= range.top &&
      row <= range.bottom
    );
  }

  /** The records of the selection: the checked ones when any, else the range's rows. */
  selectionRecords(): T[] {
    const checked = this.sheet.checked.checkedRecords;
    if (checked.length) return checked;
    const range = this.range && this.sheet.rows.recordRange(this.range);
    if (!range) return [];
    return this.sheet.args.records.slice(range.top, range.bottom + 1);
  }

  /* -------------------------------------------------------------------- */
  /* Called by the cell renderer                                           */
  /* -------------------------------------------------------------------- */

  isSelected(row: number, col: number): boolean {
    const range = this.range;
    return (
      !!range &&
      row >= range.top &&
      row <= range.bottom &&
      col >= range.left &&
      col <= range.right
    );
  }

  touchedAt(pos: Pos): Touched {
    const record = this.sheet.rows.recordAt(pos.row);
    const field = this.sheet.fields.visibleFields[pos.col];
    if (record === undefined || !field) return [];
    return [{ id: this.sheet.args.getRecordId(record), fieldId: field.id }];
  }

  /** Every existing cell of a grid range (its records), optionally only the writable ones. */
  touchedIn(gridRange: Range, writableOnly: boolean): Touched {
    const range = this.sheet.rows.recordRange(gridRange);
    return range ? this.touchedInRecords(range, writableOnly) : [];
  }

  /** Every existing cell of a record range (clamped), optionally only the writable ones. */
  touchedInRecords(range: Range, writableOnly: boolean): Touched {
    const touched: Touched = [];
    const records = this.sheet.args.records;
    const fields = this.sheet.fields.visibleFields;
    for (
      let row = Math.max(range.top, 0);
      row <= Math.min(range.bottom, records.length - 1);
      row++
    ) {
      const record = records[row]!;
      for (
        let col = Math.max(range.left, 0);
        col <= Math.min(range.right, fields.length - 1);
        col++
      ) {
        const field = fields[col]!;
        if (writableOnly && isReadOnly(this.sheet.context, field, record))
          continue;
        touched.push({
          id: this.sheet.args.getRecordId(record),
          fieldId: field.id
        });
      }
    }
    return touched;
  }

  /** Selects whole rows: from `row`, or from the range's anchor with `extend`. */
  selectRows(row: number, extend: boolean): void {
    const last = this.sheet.fields.visibleFields.length - 1;
    const anchorRow =
      extend && this.anchor
        ? this.sheet.rows.clampToRecordRow(this.anchor.row, row)
        : row;
    this.anchor = { row: anchorRow, col: 0 };
    this.head = { row, col: last };
    this.rangeKind = 'rows';
  }

  /** Selects whole columns of the records: from `col`, or from the range's anchor with `extend`. */
  selectColumns(col: number, extend: boolean): void {
    const lastRow = this.sheet.rows.rowModel.lastRecordRow;
    if (lastRow < 0) return;
    const anchorCol =
      extend && this.anchor && this.rangeKind === 'columns'
        ? this.anchor.col
        : col;
    this.anchor = {
      row: this.sheet.rows.rowModel.firstRecordRow,
      col: anchorCol
    };
    this.head = { row: lastRow, col };
    this.rangeKind = 'columns';
  }

  /**
   * Moves the range's head to `target` (Shift+arrows, Shift+click, the
   * edge jumps): the active cell, the anchor, keeps DOM focus and the
   * head is scrolled into view (V03 batch 1, "the active cell stays at the
   * anchor").
   */
  extendHead(target: Pos): void {
    const anchor =
      this.anchor && this.rangeKind === 'cells'
        ? this.anchor
        : this.sheet.focus.domCursor;
    if (!anchor) return;
    this.anchor = anchor;
    this.head = target;
    this.rangeKind = 'cells';
    this.sheet.scroll.revealCell(target);
  }

  /**
   * Focuses `target`, which may not be rendered (the grid scrolls to it):
   * the range is set here, so the focus that comes later keeps it.
   */
  moveFocus(target: Pos, extend: boolean): void {
    // a group header keeps no range (V03 9.1), also when focus stays on it
    // (an edge key that does not move): nothing to clear, fill or paste over
    if (
      this.sheet.rows.isGrouped &&
      this.sheet.rows.rowKind(target.row) === 'group'
    ) {
      this.anchor = null;
      this.head = null;
      this.rangeKind = 'cells';
      this.sheet.focus.domCursor = null;
      this.sheet.dom.focusGridCell(target);
      return;
    }
    if (extend && this.anchor && this.sheet.rows.isRecordRow(target.row)) {
      this.head = target;
    } else {
      this.anchor = target;
      this.head = target;
    }
    this.rangeKind = 'cells';
    // onFocusIn sees the cell it already knows and keeps the range
    this.sheet.focus.domCursor = target;
    this.sheet.dom.focusGridCell(target);
  }

  /** Delete and Backspace: the range's writable cells get their empty value. */
  clearSelection(): void {
    const range = this.range && this.sheet.rows.recordRange(this.range);
    if (!range) return;
    this.sheet.changes.emit(
      clearRange(this.sheet.context, range),
      this.touchedInRecords(range, true)
    );
  }

  /** `SheetApi.focusCell`. */
  focusRecordCell({
    recordId,
    fieldId
  }: {
    recordId: RecordId;
    fieldId: string;
  }): void {
    const row = this.sheet.rows.rowOf(
      recordId,
      this.sheet.rows.hintOf(this.head?.row)
    );
    const col = this.sheet.fields.visibleFields.findIndex(
      (field) => field.id === fieldId
    );
    if (row < 0 || col < 0) return;
    const pos = { row: this.sheet.rows.gridRowOf(row), col };
    this.anchor = pos;
    this.head = pos;
    this.rangeKind = 'cells';
    this.sheet.focus.domCursor = pos;
    this.sheet.dom.focusGridCell(pos);
  }

  /** Keeps the selection inside the visible fields after `@fields` changed. */
  clampSelection(): void {
    const last = this.sheet.fields.visibleFields.length - 1;
    const fix = (pos: Pos | null): Pos | null =>
      pos && pos.col > last ? { row: pos.row, col: Math.max(last, 0) } : pos;
    if (last < 0) {
      if (this.anchor || this.head) {
        this.anchor = null;
        this.head = null;
      }
      return;
    }
    const anchor = fix(this.anchor);
    const head = fix(this.head);
    if (anchor !== this.anchor) this.anchor = anchor;
    if (head !== this.head) this.head = head;
  }
}
