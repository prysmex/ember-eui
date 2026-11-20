/**
 * The paste builder shared by `pasteMatrix` (unresolved texts are
 * rejections) and `planPaste` (they are pending cells for `@onResolve`).
 * Not exported from the core's index.
 */
import {
  cellKey,
  isReadOnly,
  resolveType,
  sameFieldValue,
  valueOf
} from './fields.ts';

import type {
  CellPatch,
  CellRejection,
  ChangeSet,
  EuiSheetField,
  NewOption,
  ParseResult,
  PendingCell,
  Pos,
  RecordId,
  RecordInsert,
  SheetContext
} from './types.ts';

/** The cell's texts to resolve: the type's `resolve.parts`, else the `unresolved` text. */
export function partsOf<T>(
  ctx: SheetContext<T>,
  field: EuiSheetField<T>,
  text: string,
  unresolved: string,
  record: T | undefined,
  source: 'edit' | 'paste'
): string[] {
  const type = resolveType(ctx.types, field);
  if (!type.resolve) return [unresolved];
  return type.resolve.parts(text, field, {
    record,
    messages: ctx.messages,
    source
  });
}

export interface PasteParts {
  changeSet: ChangeSet | null;
  pending: PendingCell[];
  /** The record (or the accepted values of an inserted row) of each pending cell, same order. */
  pendingRecords: unknown[];
}

/**
 * Where the lines past `ctx.records` are inserted (V03-DESIGN.md 8.5), for
 * a grouped sheet: a group's add row, or the lines that run past the last
 * record. Without it, after the last record as v0.2.
 */
export interface PasteInsert {
  /** The `index` of the first insert (the next ones follow it). Default `ctx.records.length`. */
  index?: number;
  /** The first insert's anchor (the next ones follow the previous insert). Default: after the last record; `null`: none. */
  anchor?: RecordInsert['anchor'] | null;
  /** Values every insert gets (a group's): a pasted text for one of these fields is not read, the value wins. */
  values?: Record<string, unknown>;
  /** `RecordInsert.groupKey` of every insert. */
  groupKey?: string;
}

/**
 * Cell `[i][j]` goes to `anchor + (i, j)` (see `pasteMatrix`). With
 * `resolve`, a text the type answers `{ unresolved }` for is a pending cell
 * instead of a rejection; a row past the end with only pending cells still
 * gets its insert. `insert` places and fills the rows past the end.
 */
export function buildPaste<T>(
  ctx: SheetContext<T>,
  anchor: Pos,
  matrix: readonly (readonly string[])[],
  options: {
    nextTempId?: () => string;
    resolve?: boolean;
    insert?: PasteInsert;
  }
): PasteParts {
  const patches: CellPatch[] = [];
  const inserts: RecordInsert[] = [];
  const rejected: CellRejection[] = [];
  const newOptions: NewOption[] = [];
  const pending: PendingCell[] = [];
  const pendingRecords: unknown[] = [];
  const seenOptions = new Set<string>();

  matrix.forEach((line, i) => {
    const record = ctx.records[anchor.row + i];
    const accepted: Record<string, unknown> = {};
    // a row past the end: the insert's own values win over its cells
    const insertValues =
      record === undefined ? options.insert?.values : undefined;
    let tempId: string | undefined;
    let recordId: RecordId | undefined;
    if (record !== undefined) recordId = ctx.getRecordId(record);
    const ensureTempId = () => {
      tempId ??= options.nextTempId?.() ?? `new-${inserts.length}`;
      return tempId;
    };

    line.forEach((text, j) => {
      const field: EuiSheetField<T> | undefined = ctx.fields[anchor.col + j];
      if (!field) return;
      // the insert's own value wins: its pasted text is not read, and the
      // line still makes its insert
      if (insertValues && field.id in insertValues) {
        ensureTempId();
        return;
      }
      const contextRecord = (
        record !== undefined
          ? { ...record, ...accepted }
          : { ...accepted, ...insertValues }
      ) as T;
      if (isReadOnly(ctx, field, contextRecord)) return;
      const type = resolveType(ctx.types, field);
      const result: ParseResult<unknown> = type.parse(text, field, {
        record: contextRecord,
        messages: ctx.messages,
        source: 'paste'
      });
      if ('unresolved' in result && options.resolve) {
        const cell: PendingCell = {
          fieldId: field.id,
          text,
          parts: partsOf(
            ctx,
            field,
            text,
            result.unresolved,
            contextRecord,
            'paste'
          )
        };
        if (record !== undefined) cell.recordId = recordId!;
        else cell.tempId = ensureTempId();
        pending.push(cell);
        pendingRecords.push(
          record !== undefined
            ? record
            : insertValues
              ? { ...accepted, ...insertValues }
              : accepted
        );
        return;
      }
      if (!('value' in result)) {
        const message =
          'error' in result
            ? result.error
            : ctx.messages.unresolved(result.unresolved);
        rejected.push(
          record !== undefined
            ? { recordId: recordId!, fieldId: field.id, text, message }
            : { tempId: ensureTempId(), fieldId: field.id, text, message }
        );
        return;
      }
      const value = result.value;
      accepted[field.id] = value;
      const created = [
        ...(result.newOption ? [result.newOption] : []),
        ...(result.newOptions ?? [])
      ];
      for (const option of created) {
        const key = cellKey(String(option.value), field.id);
        if (!seenOptions.has(key)) {
          seenOptions.add(key);
          newOptions.push({ fieldId: field.id, option });
        }
      }
      if (record !== undefined) {
        const from = valueOf(record, field.id);
        if (!sameFieldValue(type, from, value)) {
          patches.push({
            recordId: recordId!,
            fieldId: field.id,
            from,
            to: value
          });
        }
      } else {
        ensureTempId();
      }
    });

    if (record === undefined && tempId !== undefined) {
      const into = options.insert;
      if (into) {
        // `insert`: from its index and anchor, then each after the previous
        const previous = inserts[inserts.length - 1];
        const insert: RecordInsert = {
          tempId,
          index: (into.index ?? ctx.records.length) + inserts.length,
          values: into.values ? { ...accepted, ...into.values } : accepted
        };
        const last = ctx.records[ctx.records.length - 1];
        const first =
          into.anchor === undefined
            ? last !== undefined
              ? { recordId: ctx.getRecordId(last), position: 'after' as const }
              : undefined
            : (into.anchor ?? undefined);
        const anchorOf = previous
          ? { recordId: previous.tempId, position: 'after' as const }
          : first;
        if (anchorOf) insert.anchor = anchorOf;
        if (into.groupKey !== undefined) insert.groupKey = into.groupKey;
        inserts.push(insert);
      } else {
        // after the last record, then each after the previous insert
        const previous = inserts[inserts.length - 1];
        const last = ctx.records[ctx.records.length - 1];
        const anchorId = previous
          ? previous.tempId
          : last !== undefined
            ? ctx.getRecordId(last)
            : undefined;
        const insert: RecordInsert = {
          tempId,
          index: ctx.records.length + inserts.length,
          values: accepted
        };
        if (anchorId !== undefined) {
          insert.anchor = { recordId: anchorId, position: 'after' };
        }
        inserts.push(insert);
      }
    }
  });

  const empty =
    !patches.length &&
    !inserts.length &&
    !rejected.length &&
    !newOptions.length;
  return {
    changeSet: empty
      ? null
      : {
          source: 'paste',
          patches,
          inserts,
          rejected,
          newOptions
        },
    pending,
    pendingRecords
  };
}
