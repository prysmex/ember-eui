/** The checked rows: controlled with `@onCheckedChange`, else local (V03C-DESIGN.md 3.2). */
import { cached, tracked } from '@glimmer/tracking';

import { ROW_COLUMN_ID } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { RecordId } from '../../core/index.ts';

export default class SheetChecked<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Checked rows without `@onCheckedChange`: record ids as strings. */
  @tracked localChecked: ReadonlySet<string> = new Set();

  /** The row whose checkbox was toggled last (Shift+click checks the rows between). */
  lastToggledRow: number | null = null;

  /* Checked rows: controlled with `@onCheckedChange`, else local */

  @cached
  get checkedIds(): ReadonlySet<string> {
    if (!this.sheet.args.onCheckedChange) return this.localChecked;
    return new Set((this.sheet.args.checkedRecordIds ?? []).map(String));
  }

  isChecked(row: number): boolean {
    const record = this.sheet.rows.recordAt(row);
    return (
      record !== undefined &&
      this.checkedIds.has(String(this.sheet.args.getRecordId(record)))
    );
  }

  /** The checked records of `@records`, in their order. */
  get checkedRecords(): T[] {
    const checked = this.checkedIds;
    if (!checked.size) return [];
    return this.sheet.args.records.filter((record) =>
      checked.has(String(this.sheet.args.getRecordId(record)))
    );
  }

  /** The header checkbox: every record of `@records` checked, some, or none. */
  get checkedState(): 'all' | 'some' | 'none' {
    const count = this.checkedRecords.length;
    if (!count) return 'none';
    return count === this.sheet.args.records.length ? 'all' : 'some';
  }

  /** Sets the checked ids (strings), through `@onCheckedChange` or locally. */
  setChecked(ids: ReadonlySet<string>): void {
    const handler = this.sheet.args.onCheckedChange;
    if (!handler) {
      this.localChecked = ids;
      return;
    }
    // the owner's ids keep their type: from `@records`, else as passed
    const known = new Map<string, RecordId>();
    for (const id of this.sheet.args.checkedRecordIds ?? [])
      known.set(String(id), id);
    for (const record of this.sheet.args.records) {
      const id = this.sheet.args.getRecordId(record);
      known.set(String(id), id);
    }
    handler([...ids].map((id) => known.get(id) ?? id));
  }

  /** Toggles a row's checkbox; with `shift`, the rows from the last toggled one get the same state. */
  toggleChecked(row: number, shift: boolean): void {
    const record = this.sheet.rows.recordAt(row);
    if (record === undefined) return;
    const getId = this.sheet.args.getRecordId;
    const value = !this.checkedIds.has(String(getId(record)));
    const from =
      shift && this.lastToggledRow !== null ? this.lastToggledRow : row;
    // the records between the two rows (grid rows); never empty, `row` is one
    const span = this.sheet.rows.recordRange({
      top: Math.min(from, row),
      bottom: Math.max(from, row),
      left: 0,
      right: 0
    })!;
    const next = new Set(this.checkedIds);
    for (let r = span.top; r <= span.bottom; r++) {
      const id = String(getId(this.sheet.args.records[r]!));
      if (value) next.add(id);
      else next.delete(id);
    }
    this.lastToggledRow = row;
    this.setChecked(next);
  }

  /** The header checkbox: checks every record, or none when all are checked. */
  toggleAllChecked(): void {
    const ids = this.sheet.args.records.map((record) =>
      String(this.sheet.args.getRecordId(record))
    );
    const next = new Set(this.checkedIds);
    if (this.checkedState === 'all') ids.forEach((id) => next.delete(id));
    else ids.forEach((id) => next.add(id));
    this.setChecked(next);
  }

  isCheckedRowsTarget(target: EventTarget | null): boolean {
    if (!this.checkedRecords.length || !(target instanceof Element)) {
      return false;
    }
    const rowCell = this.sheet.dom.rowNumberCell(target);
    if (rowCell) return this.sheet.dom.isClipboardTarget(target, rowCell);
    const header = target.closest<HTMLElement>(
      `[role=columnheader][data-gridcell-column-id="${ROW_COLUMN_ID}"]`
    );
    return (
      !!header &&
      !!this.sheet.wrapper?.contains(header) &&
      this.sheet.dom.isClipboardTarget(target, header)
    );
  }
}
