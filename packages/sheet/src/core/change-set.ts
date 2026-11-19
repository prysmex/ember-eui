/**
 * Change-set builders: what an edit, a clear or a paste writes, as plain
 * data the owner applies (PACKAGE-DESIGN.md 5.5).
 */
import { cellKey, isReadOnly, resolveType, valueOf } from './fields.ts';

import type {
  CellPatch,
  CellRejection,
  ChangeSet,
  EuiSheetField,
  NewOption,
  ParseResult,
  Pos,
  Range,
  RecordId,
  RecordInsert,
  SheetContext
} from './types.ts';

export function toRange(anchor: Pos, head: Pos): Range {
  return {
    top: Math.min(anchor.row, head.row),
    left: Math.min(anchor.col, head.col),
    bottom: Math.max(anchor.row, head.row),
    right: Math.max(anchor.col, head.col)
  };
}

function changeSet(
  source: ChangeSet['source'],
  parts: Partial<Omit<ChangeSet, 'source'>>
): ChangeSet {
  return {
    source,
    patches: parts.patches ?? [],
    inserts: parts.inserts ?? [],
    rejected: parts.rejected ?? [],
    newOptions: parts.newOptions ?? []
  };
}

function rejectionMessage(
  ctx: SheetContext<unknown>,
  result: ParseResult<unknown>
): string | undefined {
  if ('error' in result) return result.error;
  if ('unresolved' in result) return ctx.messages.unresolved(result.unresolved);
  return undefined;
}

/** The copy text of each cell of the range, clamped to existing rows and fields. */
export function rangeMatrix<T>(ctx: SheetContext<T>, range: Range): string[][] {
  const bottom = Math.min(range.bottom, ctx.records.length - 1);
  const right = Math.min(range.right, ctx.fields.length - 1);
  const matrix: string[][] = [];
  for (let row = Math.max(range.top, 0); row <= bottom; row++) {
    const record = ctx.records[row];
    const line: string[] = [];
    for (let col = Math.max(range.left, 0); col <= right; col++) {
      const field = ctx.fields[col]!;
      const type = resolveType(ctx.types, field);
      const context = { record, messages: ctx.messages };
      const value = valueOf(record, field.id);
      line.push(
        type.copyText
          ? type.copyText(value, field, context)
          : type.format(value, field, context)
      );
    }
    matrix.push(line);
  }
  return matrix;
}

/**
 * The text typed into one cell: one patch, or one rejection when the type
 * cannot read it. `null` when the cell is read-only, does not exist, or the
 * value is unchanged.
 */
export function commitText<T>(
  ctx: SheetContext<T>,
  pos: Pos,
  text: string
): ChangeSet | null {
  const record = ctx.records[pos.row];
  const field = ctx.fields[pos.col];
  if (record === undefined || !field || isReadOnly(ctx, field, record)) {
    return null;
  }
  const recordId = ctx.getRecordId(record);
  const result = resolveType(ctx.types, field).parse(text, field, {
    record,
    messages: ctx.messages,
    source: 'edit'
  });
  const message = rejectionMessage(ctx as SheetContext<unknown>, result);
  if (message !== undefined) {
    return changeSet('edit', {
      rejected: [{ recordId, fieldId: field.id, text, message }]
    });
  }
  const { value, newOption } = result as {
    value: unknown;
    newOption?: NewOption['option'];
  };
  const from = valueOf(record, field.id);
  if (Object.is(from, value)) return null;
  return changeSet('edit', {
    patches: [{ recordId, fieldId: field.id, from, to: value }],
    newOptions: newOption ? [{ fieldId: field.id, option: newOption }] : []
  });
}

/** A value that needs no parsing (a picked option, a toggled checkbox). `null` when read-only or unchanged. */
export function commitValue<T>(
  ctx: SheetContext<T>,
  pos: Pos,
  value: unknown
): ChangeSet | null {
  const record = ctx.records[pos.row];
  const field = ctx.fields[pos.col];
  if (record === undefined || !field || isReadOnly(ctx, field, record)) {
    return null;
  }
  const from = valueOf(record, field.id);
  if (Object.is(from, value)) return null;
  return changeSet('edit', {
    patches: [
      { recordId: ctx.getRecordId(record), fieldId: field.id, from, to: value }
    ]
  });
}

/** The type's empty value (`parse('')`) per non-read-only cell whose value differs; `null` when nothing changes. */
export function clearRange<T>(
  ctx: SheetContext<T>,
  range: Range
): ChangeSet | null {
  const patches: CellPatch[] = [];
  const bottom = Math.min(range.bottom, ctx.records.length - 1);
  const right = Math.min(range.right, ctx.fields.length - 1);
  for (let row = Math.max(range.top, 0); row <= bottom; row++) {
    const record = ctx.records[row]!;
    for (let col = Math.max(range.left, 0); col <= right; col++) {
      const field = ctx.fields[col]!;
      if (isReadOnly(ctx, field, record)) continue;
      const result = resolveType(ctx.types, field).parse('', field, {
        record,
        messages: ctx.messages,
        source: 'clear'
      });
      if (!('value' in result)) continue;
      const from = valueOf(record, field.id);
      if (Object.is(from, result.value)) continue;
      patches.push({
        recordId: ctx.getRecordId(record),
        fieldId: field.id,
        from,
        to: result.value
      });
    }
  }
  return patches.length ? changeSet('clear', { patches }) : null;
}

/**
 * Cell `[i][j]` goes to `anchor + (i, j)`. Columns past the last field are
 * dropped, read-only cells skipped (per record). Each row is parsed left to
 * right against the record merged with the values accepted so far in that
 * row. A text the type cannot read gives a rejection instead of a patch.
 * Rows past the end give one insert each when they have at least one
 * accepted or rejected cell.
 */
export function pasteMatrix<T>(
  ctx: SheetContext<T>,
  anchor: Pos,
  matrix: readonly (readonly string[])[],
  options: { nextTempId?: () => string } = {}
): ChangeSet | null {
  const patches: CellPatch[] = [];
  const inserts: RecordInsert[] = [];
  const rejected: CellRejection[] = [];
  const newOptions: NewOption[] = [];
  const seenOptions = new Set<string>();

  matrix.forEach((line, i) => {
    const record = ctx.records[anchor.row + i];
    const accepted: Record<string, unknown> = {};
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
      const contextRecord = (
        record !== undefined ? { ...record, ...accepted } : { ...accepted }
      ) as T;
      if (isReadOnly(ctx, field, contextRecord)) return;
      const result = resolveType(ctx.types, field).parse(text, field, {
        record: contextRecord,
        messages: ctx.messages,
        source: 'paste'
      });
      const message = rejectionMessage(ctx as SheetContext<unknown>, result);
      if (message !== undefined) {
        rejected.push(
          record !== undefined
            ? { recordId: recordId!, fieldId: field.id, text, message }
            : { tempId: ensureTempId(), fieldId: field.id, text, message }
        );
        return;
      }
      const { value, newOption } = result as {
        value: unknown;
        newOption?: NewOption['option'];
      };
      accepted[field.id] = value;
      if (newOption) {
        const key = cellKey(String(newOption.value), field.id);
        if (!seenOptions.has(key)) {
          seenOptions.add(key);
          newOptions.push({ fieldId: field.id, option: newOption });
        }
      }
      if (record !== undefined) {
        const from = valueOf(record, field.id);
        if (!Object.is(from, value)) {
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
      inserts.push({
        tempId,
        index: ctx.records.length + inserts.length,
        values: accepted
      });
    }
  });

  if (
    !patches.length &&
    !inserts.length &&
    !rejected.length &&
    !newOptions.length
  ) {
    return null;
  }
  return changeSet('paste', { patches, inserts, rejected, newOptions });
}

/**
 * The records with the change set applied (pure). Patched records are new
 * objects, the others keep their identity; inserts are appended in `index`
 * order. `rejected` and `newOptions` do not touch records.
 */
export function applyChangeSet<T extends object>(
  records: readonly T[],
  changeSet: ChangeSet,
  options: {
    getRecordId: (record: T) => RecordId;
    /** Default: `{ id: tempId, ...values }`. */
    createRecord?: (values: Record<string, unknown>, tempId: string) => T;
  }
): T[] {
  const { getRecordId, createRecord } = options;
  const byId = new Map<RecordId, Record<string, unknown>>();
  for (const patch of changeSet.patches) {
    const values = byId.get(patch.recordId) ?? {};
    values[patch.fieldId] = patch.to;
    byId.set(patch.recordId, values);
  }
  const next = records.map((record) => {
    const values = byId.get(getRecordId(record));
    return values ? ({ ...record, ...values } as T) : record;
  });
  const inserts = [...changeSet.inserts].sort((a, b) => a.index - b.index);
  for (const insert of inserts) {
    next.push(
      createRecord
        ? createRecord(insert.values, insert.tempId)
        : ({ id: insert.tempId, ...insert.values } as unknown as T)
    );
  }
  return next;
}

/**
 * `fields` with the options created on paste appended (pure). The same array
 * when there are none. A field whose `options` is a function is left alone:
 * its owner adds the option to its own source.
 */
export function applyNewOptions<F extends EuiSheetField>(
  fields: readonly F[],
  changeSet: ChangeSet
): F[] {
  if (!changeSet.newOptions.length) return fields as F[];
  return fields.map((field) => {
    const added = changeSet.newOptions.filter(
      (entry) => entry.fieldId === field.id
    );
    const options = field['options'];
    if (!added.length || !Array.isArray(options)) return field;
    const next = [...(options as NewOption['option'][])];
    for (const { option } of added) {
      if (!next.some((existing) => existing.value === option.value)) {
        next.push(option);
      }
    }
    return next.length === options.length ? field : { ...field, options: next };
  });
}
