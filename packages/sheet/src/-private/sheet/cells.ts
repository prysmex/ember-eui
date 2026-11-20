/** What the cell renderer calls: a cell's view, its link, rejection and commit (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';

import {
  cellKey,
  commitValue,
  isReadOnly,
  mergeErrors,
  safeLink,
  validateCell,
  valueOf
} from '../../core/index.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { EuiSheetField, Pos, RecordId } from '../../core/index.ts';
import type { EuiSheetFieldType } from '../../types.ts';
import type { Rejection } from '../rejections.ts';
import type { CellView } from './types.ts';

export default class SheetCells<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Texts a type could not read, by cellKey (PACKAGE-DESIGN.md 6, 7.5). */
  @tracked rejections: ReadonlyMap<string, Rejection> = new Map();

  /** The rejection of a cell, unless the owner changed the value since. */
  liveRejection(
    record: T,
    recordId: RecordId,
    fieldId: string
  ): Rejection | undefined {
    const rejection = this.rejections.get(cellKey(recordId, fieldId));
    if (!rejection) return undefined;
    return this.sheet.fields.valueEquals(
      fieldId,
      rejection.seenValue,
      valueOf(record, fieldId)
    )
      ? rejection
      : undefined;
  }

  /** `@validate`'s errors of a cell, unless its record changed since the run started. */
  validatedErrors(
    record: T,
    recordId: RecordId,
    fieldId: string
  ): string | string[] | undefined {
    const validation = this.sheet.validate.validation;
    if (!validation) return undefined;
    const id = String(recordId);
    if (validation.records.get(id) !== record) return undefined;
    return validation.errors[id]?.[fieldId];
  }

  cellView(row: number, col: number, fieldId: string): CellView | null {
    const record = this.sheet.rows.recordAt(row);
    const field = this.sheet.fields.visibleFields.find((f) => f.id === fieldId);
    if (record === undefined || !field) return null;
    const view = this.cellViewFor(
      record,
      field,
      this.sheet.selection.isSelected(row, col)
    );
    const drop = this.sheet.uploads.dropPos;
    if (drop && drop.row === row && drop.col === col) view.dropTarget = true;
    // `@currentMatch` (V03 11.1)
    const match = this.sheet.scroll.matchPos;
    if (match && match.row === row && match.col === col) view.match = true;
    return view;
  }

  /** A record's field as a cell shows it: the grid's cells and the expanded record's boxes. */
  cellViewFor(record: T, field: EuiSheetField<T>, selected = false): CellView {
    const ctx = this.sheet.context;
    const type = this.sheet.fields.typeOf(field);
    const value = valueOf(record, field.id);
    const recordId = ctx.getRecordId(record);
    const rejection = this.liveRejection(record, recordId, field.id);
    const pending = this.sheet.resolve.pendingCells.get(
      cellKey(recordId, field.id)
    );
    // a button cell (V03 10.3.1): its press's pending state and error
    const pressable = this.sheet.buttons.pressable(type, field, record);
    const pressing =
      pressable && this.sheet.buttons.isPending(recordId, field.id);
    const pressError = pressable
      ? this.sheet.buttons.errorOf(recordId, field.id)
      : undefined;
    const text =
      pending && pending.text !== null
        ? pending.text
        : rejection
          ? rejection.text
          : type.format(value, field, { record, messages: ctx.messages });
    // a rejected cell shows only its rejection and the owner's errors: the
    // other layers describe the old value (PACKAGE-DESIGN.md 6, 9.4)
    const errors = rejection
      ? mergeErrors(
          rejection.message,
          this.sheet.args.cellErrors?.[String(recordId)]?.[field.id]
        )
      : mergeErrors(
          validateCell(ctx, field, record),
          this.validatedErrors(record, recordId, field.id),
          this.sheet.args.cellErrors?.[String(recordId)]?.[field.id],
          pressError
        );
    return {
      record,
      field,
      type,
      value,
      text,
      // a pending text is shown as text, like a rejected one
      rejected: !!rejection || (!!pending && pending.text !== null),
      errors: pending ? [] : errors,
      selected,
      readOnly: isReadOnly(ctx, field, record),
      pending: !!pending || pressing,
      link: this.linkOf(type, field, value),
      dropTarget: false,
      pressable,
      disabled: pressable && this.sheet.buttons.isDisabled(field, record)
    };
  }

  /** `type.link(value)`, when it is a link the sheet opens. */
  linkOf(
    type: EuiSheetFieldType,
    field: EuiSheetField,
    value: unknown
  ): string | undefined {
    return type.link ? safeLink(type.link(value as never, field)) : undefined;
  }

  /** Opens a link in a new tab; only http:, https:, mailto: and tel: (checked again here). */
  openLink(href: string | undefined): boolean {
    const safe = safeLink(href);
    if (!safe) return false;
    window.open(safe, '_blank', 'noopener');
    return true;
  }

  /** A cell component's `@onCommit(value)`, at a grid row. */
  commitCellValue(row: number, col: number, value: unknown): void {
    const pos = { row, col };
    const touched = this.sheet.selection.touchedAt(pos);
    // off a record: row -1, which the core answers with null, as before
    this.sheet.changes.emit(
      commitValue(this.sheet.context, this.sheet.rows.recordPos(pos), value),
      touched
    );
  }

  /** Whether the cell at `pos` opens an editor. */
  canEdit(pos: Pos): boolean {
    const record = this.sheet.rows.recordAt(pos.row);
    const field = this.sheet.fields.visibleFields[pos.col];
    if (record === undefined || !field) return false;
    return (
      !!this.sheet.fields.typeOf(field).editor &&
      !isReadOnly(this.sheet.context, field, record)
    );
  }
}
