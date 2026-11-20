/** The expanded record: its shell, stepping, and the form's commits (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';

import { clearRange, commitValue, valueOf } from '../../core/index.ts';
import { afterRender } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type {
  ChangeSet,
  EuiSheetField,
  Pos,
  RecordId,
  SheetContext
} from '../../core/index.ts';
import type { ExpandedFrom } from './types.ts';

export default class SheetExpanded<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The expanded record without `@onExpandedRecordChange`. */
  @tracked localExpandedId: RecordId | null = null;
  /**
   * An editor is open in the expanded record's form: the shell's focus
   * trap is paused, so focus can reach a surface the editor renders
   * outside the shell (a wormholed calendar; N3).
   */
  @tracked formEditorOpen = false;
  /** Where the expanded record was opened from. */
  expandedFrom: ExpandedFrom | null = null;

  /* -------------------------------------------------------------------- */
  /* The expanded record (V02-DESIGN.md 5.7)                               */
  /* -------------------------------------------------------------------- */

  /** Controlled with `@onExpandedRecordChange`, else local. */
  get expandedId(): RecordId | null {
    return this.sheet.args.onExpandedRecordChange
      ? (this.sheet.args.expandedRecordId ?? null)
      : this.localExpandedId;
  }

  setExpanded(id: RecordId | null): void {
    if (id === null && this.formEditorOpen) this.formEditorOpen = false;
    if (this.sheet.args.onExpandedRecordChange)
      this.sheet.args.onExpandedRecordChange(id);
    else this.localExpandedId = id;
  }

  /** The expanded record, while it is in `@records`. */
  get expandedRecordValue(): T | undefined {
    const id = this.expandedId;
    if (id === null) return undefined;
    return this.sheet.args.records[this.sheet.rows.rowOf(id, 0)];
  }

  get expandedShell(): 'flyout' | 'modal' {
    return this.sheet.args.expandedRecord === 'modal' ? 'modal' : 'flyout';
  }

  /** Opens a record of `@records`; `from` is the cell focus returns to on close. */
  expandRecord(recordId: RecordId, from: ExpandedFrom | null): void {
    if (
      this.sheet.rows.rowOf(
        recordId,
        this.sheet.rows.hintOf(this.sheet.selection.head?.row)
      ) < 0
    )
      return;
    if (this.sheet.edit.editing) this.sheet.edit.commit({ refocus: false });
    this.expandedFrom = from ?? this.expandedFrom;
    this.setExpanded(recordId);
  }

  /** Closes it and focuses the cell it was opened from, when that row still exists. */
  closeExpanded = (): void => {
    const from = this.expandedFrom;
    this.expandedFrom = null;
    this.setExpanded(null);
    if (!from) return;
    afterRender(this.sheet, () => {
      // a controlled owner may keep it open
      if (this.expandedId !== null) {
        this.expandedFrom ??= from;
        return;
      }
      const row = this.sheet.rows.rowOf(
        from.recordId,
        this.sheet.rows.hintOf(this.sheet.selection.head?.row)
      );
      if (row < 0) return;
      if (from.fieldId === null) {
        this.sheet.focus.keepRangeOnFocus = true;
        this.sheet.dom.focusRowNumberCell(this.sheet.rows.gridRowOf(row));
      } else {
        this.sheet.selection.focusRecordCell({
          recordId: from.recordId,
          fieldId: from.fieldId
        });
      }
    });
  };

  /** The record `step` rows from the expanded one, or null at either end. */
  expandedStep(step: number): T | null {
    const id = this.expandedId;
    if (id === null) return null;
    const row = this.sheet.rows.rowOf(id, 0);
    if (row < 0) return null;
    return this.sheet.args.records[row + step] ?? null;
  }

  stepExpanded(step: number): void {
    const record = this.expandedStep(step);
    if (record) this.setExpanded(this.sheet.args.getRecordId(record));
  }

  /** The expanded record's title: its first field's text, else "Record n". */
  recordTitleOf(record: T): string {
    const field = this.sheet.fields.allFields[0];
    const text = field
      ? this.sheet.fields
          .typeOf(field)
          .format(valueOf(record, field.id), field, {
            record,
            messages: this.sheet.messages
          })
      : '';
    if (text.trim()) return text;
    const row = this.sheet.rows.rowOf(this.sheet.args.getRecordId(record), 0);
    return this.sheet.messages.recordTitle(
      this.sheet.rows.numberOf(Math.max(row, 0))
    );
  }

  /** A one-record context for the form: every field, visible and hidden. */
  formContext(record: T): { ctx: SheetContext<T>; record: T } | null {
    // the current object of the record: the form may hold an older one
    const row = this.sheet.rows.rowOf(this.sheet.args.getRecordId(record), 0);
    const current = this.sheet.args.records[row];
    if (current === undefined) return null;
    return {
      ctx: {
        ...this.sheet.context,
        records: [current],
        fields: this.sheet.fields.allFields
      },
      record: current
    };
  }

  /** A value saved from the form (a picked option, a toggled checkbox). */
  commitFormValue(record: T, field: EuiSheetField<T>, value: unknown): void {
    this.commitForm(record, field, (ctx, pos) => commitValue(ctx, pos, value));
  }

  /** A text typed in the form, parsed by the field's type. */
  commitFormText(record: T, field: EuiSheetField<T>, text: string): void {
    const form = this.formContext(record);
    if (!form) return;
    const col = this.sheet.fields.allFields.indexOf(field);
    if (col < 0) return;
    this.sheet.changes.emitText(form.ctx, { row: 0, col }, text, [
      { id: this.sheet.args.getRecordId(form.record), fieldId: field.id }
    ]);
  }

  /** Delete or Backspace on a box: the type's empty value. */
  clearFormField(record: T, field: EuiSheetField<T>): void {
    this.commitForm(record, field, (ctx, pos) =>
      clearRange(ctx, {
        top: pos.row,
        left: pos.col,
        bottom: pos.row,
        right: pos.col
      })
    );
  }

  commitForm(
    record: T,
    field: EuiSheetField<T>,
    build: (ctx: SheetContext<T>, pos: Pos) => ChangeSet | null
  ): void {
    const form = this.formContext(record);
    if (!form) return;
    const col = this.sheet.fields.allFields.indexOf(field);
    if (col < 0) return;
    const changeSet = build(form.ctx, { row: 0, col });
    this.sheet.changes.emit(changeSet, [
      { id: this.sheet.args.getRecordId(form.record), fieldId: field.id }
    ]);
  }

  /** Runs `fn` after the next render (the form focuses a box). */
  afterFormRender(fn: () => void): void {
    afterRender(this.sheet, fn);
  }
}
