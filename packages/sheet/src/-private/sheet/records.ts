/** Records: insert, delete, duplicate (V03C-DESIGN.md 3.2). */
import {
  deleteRecords,
  duplicateRecords,
  insertRecords,
  isReadOnly
} from '../../core/index.ts';
import { afterRender, nextTempId } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { RecordId, RecordInsert } from '../../core/index.ts';
import type { PendingFocus } from './types.ts';

export default class SheetRecords<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /* Following `@records` (V02-DESIGN.md 3.2, 3.3) */
  /** A cell to focus once its record is rendered (inserted rows). */
  pendingFocus: PendingFocus | null = null;

  /** Focuses the pending cell once its record is in `@records` (it is rendered by now). */
  applyPendingFocus(): void {
    const pending = this.pendingFocus;
    if (!pending) return;
    // `lastIds` and `lastRowModel` are of the same render
    const model = this.sheet.lastRowModel ?? this.sheet.rows.rowModel;
    const row = model.gridRowOf(this.sheet.lastIds.indexOf(pending.id));
    if (row < 0) return;
    this.pendingFocus = null;
    const col = Math.max(
      0,
      this.sheet.fields.visibleFields.findIndex(
        (field) => field.id === pending.fieldId
      )
    );
    const pos = { row, col };
    this.sheet.selection.anchor = pos;
    this.sheet.selection.head = pos;
    this.sheet.selection.rangeKind = 'cells';
    this.sheet.focus.domCursor = pos;
    this.sheet.dom.focusGridCell(pos);
  }

  /* -------------------------------------------------------------------- */
  /* Records: insert, delete, duplicate, copy (V02-DESIGN.md 5.6)          */
  /* -------------------------------------------------------------------- */

  /** `@newRecordValues` for a record between `above` and `below`. */
  newValues(
    above: T | undefined,
    below: T | undefined
  ): Record<string, unknown> {
    return this.sheet.args.newRecordValues?.({ above, below }) ?? {};
  }

  /**
   * Emits the insert of one record at `index`, next to `anchor`; then, when
   * `focusFieldId` is given, focuses that field of the new row once it is
   * rendered.
   */
  insertOne(
    index: number,
    anchor: RecordInsert['anchor'] | undefined,
    values: Record<string, unknown>,
    focusFieldId: string | null,
    groupKey?: string
  ): void {
    const changeSet = insertRecords(this.sheet.context, {
      at: index,
      anchor,
      values: [values],
      nextTempId,
      groupKey
    });
    if (this.sheet.editing) this.sheet.commit({ refocus: false });
    this.sheet.changes.emit(changeSet, []);
    if (focusFieldId !== null) {
      this.pendingFocus = {
        id: changeSet.inserts[0]!.tempId,
        fieldId: focusFieldId
      };
      afterRender(this.sheet, () => this.applyPendingFocus());
    }
  }

  /** Insert above or below a grid row (Shift+Enter, the menu); focus goes to `fieldId` of the new row. */
  insertNear(
    gridRow: number,
    position: 'before' | 'after',
    fieldId: string | null
  ): void {
    const records = this.sheet.args.records;
    // the neighbours are records: ± 1 in `@records`
    const row = this.sheet.rows.recordRowAt(gridRow);
    const record = records[row];
    if (record === undefined) return;
    const recordId = this.sheet.args.getRecordId(record);
    // grouped: into the record's group, whose values win (V03 8.4)
    const group = this.sheet.groupHeaders.groupInsertOf(gridRow);
    const values = {
      ...(position === 'after'
        ? this.newValues(record, records[row + 1])
        : this.newValues(records[row - 1], record)),
      ...group?.values
    };
    this.insertOne(
      position === 'after' ? row + 1 : row,
      { recordId, position },
      values,
      fieldId ?? this.firstEditableField(values),
      group?.groupKey
    );
  }

  /**
   * An add row (grid row `row`): the sheet's inserts a record at the end, a
   * group's one into that group (`appendToGroup`); focus goes to its first
   * editable field.
   */
  appendRecord(row: number): void {
    if (!this.sheet.canInsert) return;
    const group = this.sheet.rows.addRowGroupAt(row);
    if (group >= 0) {
      this.appendToGroup(row, group);
      return;
    }
    const records = this.sheet.args.records;
    const last = records[records.length - 1];
    const values = this.newValues(last, undefined);
    this.insertOne(
      records.length,
      last === undefined
        ? undefined
        : { recordId: this.sheet.args.getRecordId(last), position: 'after' },
      values,
      this.firstEditableField(values)
    );
  }

  /**
   * A group's add row (V03 8.4, GR9): one record after the group's last
   * loaded record, with `@newRecordValues` under the group's values (which
   * win), its `groupKey`, and an anchor when the group has a record.
   */
  appendToGroup(row: number, group: number): void {
    const records = this.sheet.args.records;
    const key = this.sheet.rows.groups[group]?.key;
    // the group's last loaded record is the row above its add row
    const last = this.sheet.rows.recordRowAt(row - 1);
    const above = last >= 0 ? records[last] : undefined;
    const values = {
      ...this.newValues(above, undefined),
      ...this.sheet.groupHeaders.groupValuesOf(group)
    };
    this.insertOne(
      last >= 0 ? last + 1 : this.sheet.rows.coreRowOf(row),
      above === undefined
        ? undefined
        : { recordId: this.sheet.args.getRecordId(above), position: 'after' },
      values,
      this.firstEditableField(values),
      key
    );
  }

  /** The first visible field a new record with these values can edit. */
  firstEditableField(values: Record<string, unknown>): string | null {
    const fields = this.sheet.fields.visibleFields;
    const field =
      fields.find((f) => !isReadOnly(this.sheet.context, f, values as T)) ??
      fields[0];
    return field?.id ?? null;
  }

  /** `SheetApi.insertRecord`: no focus change. */
  insertFromApi(options: {
    anchor?: RecordInsert['anchor'];
    values?: Record<string, unknown>;
  }): void {
    const records = this.sheet.args.records;
    const anchor = options.anchor;
    const row = anchor ? this.sheet.rows.rowOf(anchor.recordId, 0) : -1;
    if (anchor && row >= 0) {
      const index = anchor.position === 'after' ? row + 1 : row;
      const values =
        options.values ?? this.newValues(records[index - 1], records[index]);
      this.insertOne(index, anchor, values, null);
      return;
    }
    const last = records[records.length - 1];
    this.insertOne(
      records.length,
      last === undefined
        ? undefined
        : { recordId: this.sheet.args.getRecordId(last), position: 'after' },
      options.values ?? this.newValues(last, undefined),
      null
    );
  }

  /**
   * Emits the delete of these records. With `refocus`, focus goes to that
   * field of the record after them (or before them, at the end).
   */
  deleteRecordIds(
    ids: readonly RecordId[],
    refocus: false | { fieldId: string | null }
  ): void {
    const records = this.sheet.args.records;
    const changeSet = deleteRecords(records, ids, this.sheet.args.getRecordId);
    if (!changeSet) return;
    if (this.sheet.editing) this.sheet.commit({ refocus: false });
    if (refocus) {
      const gone = new Set(changeSet.deletes!.map(String));
      const removed = changeSet.removed!;
      const lastIndex = removed[removed.length - 1]!.index;
      const firstIndex = removed[0]!.index;
      const keep = (record: T | undefined) =>
        record !== undefined &&
        !gone.has(String(this.sheet.args.getRecordId(record)));
      let neighbour: T | undefined;
      for (let i = lastIndex + 1; i < records.length && !neighbour; i++) {
        if (keep(records[i])) neighbour = records[i];
      }
      for (let i = firstIndex - 1; i >= 0 && !neighbour; i--) {
        if (keep(records[i])) neighbour = records[i];
      }
      const fieldId = refocus.fieldId ?? this.sheet.fields.visibleFields[0]?.id;
      this.pendingFocus =
        neighbour && fieldId !== undefined
          ? { id: String(this.sheet.args.getRecordId(neighbour)), fieldId }
          : null;
      this.sheet.selection.anchor = null;
      this.sheet.selection.head = null;
      this.sheet.selection.rangeKind = 'cells';
    }
    this.sheet.changes.emit(changeSet, []);
  }

  /** A copy of each record right after it: every writable field, visible and hidden. */
  duplicate(records: readonly T[], fieldId: string | null): void {
    const all = this.sheet.args.records;
    const indexes = records
      .map((record) =>
        this.sheet.rows.rowOf(
          this.sheet.args.getRecordId(record),
          all.indexOf(record)
        )
      )
      .filter((index) => index >= 0);
    // grouped: each copy goes into its record's group (V03 8.4)
    const group = this.sheet.rows.isGrouped
      ? (index: number) =>
          this.sheet.groupHeaders.groupInsertOf(
            this.sheet.rows.gridRowOf(index)
          )
      : undefined;
    const changeSet = duplicateRecords(
      {
        ...this.sheet.context,
        fields: this.sheet.fields.allFields,
        readOnly: false
      },
      indexes,
      group ? { nextTempId, group } : { nextTempId }
    );
    if (!changeSet) return;
    const focusField = fieldId ?? this.sheet.fields.visibleFields[0]?.id;
    this.sheet.changes.emit(changeSet, []);
    if (focusField !== undefined) {
      this.pendingFocus = {
        id: changeSet.inserts[0]!.tempId,
        fieldId: focusField
      };
      afterRender(this.sheet, () => this.applyPendingFocus());
    }
  }
}
