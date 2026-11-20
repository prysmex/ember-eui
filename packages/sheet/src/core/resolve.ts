/**
 * Bulk resolve (V02-DESIGN.md 8.2, V9): typed or pasted text that a type
 * answers `{ unresolved }` for is sent to the owner's `@onResolve` instead
 * of being rejected. A paste emits its synchronous part at once and the
 * resolved part as a second change set (source 'resolve').
 */
import { commitText } from './change-set.ts';
import { isReadOnly, resolveType, sameFieldValue, valueOf } from './fields.ts';
import { buildPaste, partsOf } from './paste-plan.ts';

import type { PasteInsert } from './paste-plan.ts';

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
  ResolveRequest,
  ResolveResult,
  SheetContext
} from './types.ts';

export interface ResolvePlan<T> {
  /** What is written at once: patches, inserts (also for rows whose cells are all pending), rejections. */
  changeSet: ChangeSet | null;
  pending: PendingCell[];
  /** One per field of the pending cells, for `@onResolve`. */
  requests: ResolveRequest<T>[];
}

function requestsOf<T>(
  pending: readonly PendingCell[],
  records: readonly unknown[]
): ResolveRequest<T>[] {
  const byField = new Map<string, ResolveRequest<T>>();
  pending.forEach((cell, i) => {
    let request = byField.get(cell.fieldId);
    if (!request) {
      request = { fieldId: cell.fieldId, texts: [], cells: [] };
      byField.set(cell.fieldId, request);
    }
    for (const part of cell.parts) {
      if (!request.texts.includes(part)) request.texts.push(part);
    }
    const entry: ResolveRequest<T>['cells'][number] = {
      text: cell.text,
      record: records[i] as T | undefined
    };
    if (cell.recordId !== undefined) entry.recordId = cell.recordId;
    if (cell.tempId !== undefined) entry.tempId = cell.tempId;
    request.cells.push(entry);
  });
  return [...byField.values()];
}

/**
 * A paste, as `pasteMatrix` writes it, except that a text the type answers
 * `{ unresolved }` for is left out of the change set and returned as a
 * pending cell (a row past the end still gets its insert). `requests`
 * has one entry per field with the distinct texts to resolve.
 */
export function planPaste<T>(
  ctx: SheetContext<T>,
  anchor: Pos,
  matrix: readonly (readonly string[])[],
  options: { nextTempId?: () => string; insert?: PasteInsert } = {}
): ResolvePlan<T> {
  const { changeSet, pending, pendingRecords } = buildPaste(
    ctx,
    anchor,
    matrix,
    { ...options, resolve: true }
  );
  return {
    changeSet,
    pending,
    requests: requestsOf<T>(pending, pendingRecords)
  };
}

/**
 * The text typed into one cell, as `commitText` writes it, except that a
 * text the type answers `{ unresolved }` for is a pending cell (and no
 * change set).
 */
export function planCommit<T>(
  ctx: SheetContext<T>,
  pos: Pos,
  text: string
): ResolvePlan<T> {
  const record = ctx.records[pos.row];
  const field = ctx.fields[pos.col];
  const none = { changeSet: null, pending: [], requests: [] };
  if (record === undefined || !field || isReadOnly(ctx, field, record)) {
    return none;
  }
  const result = resolveType(ctx.types, field).parse(text, field, {
    record,
    messages: ctx.messages,
    source: 'edit'
  });
  if (!('unresolved' in result)) {
    return { changeSet: commitText(ctx, pos, text), pending: [], requests: [] };
  }
  const cell: PendingCell = {
    recordId: ctx.getRecordId(record),
    fieldId: field.id,
    text,
    parts: partsOf(ctx, field, text, result.unresolved, record, 'edit')
  };
  return {
    changeSet: null,
    pending: [cell],
    requests: requestsOf<T>([cell], [record])
  };
}

/** The default `combine`: the value of the one part, or an error. */
function combineOne(
  parts: Array<{ text: string; value: unknown | null }>,
  text: string,
  ctx: SheetContext<unknown>
): ParseResult<unknown> {
  const [part] = parts;
  if (!part || parts.length !== 1 || part.value == null) {
    return { error: ctx.messages.unresolved(text) };
  }
  return { value: part.value };
}

/**
 * The second change set of a resolve (source 'resolve'): a patch for each
 * pending cell whose parts the owner resolved (`from` read from `records`
 * now; a cell on a row inserted by the first change set is patched by its
 * `tempId`), a rejection for each whose `combine` fails (by default: a
 * part answered `null`). `ctx.fields` must hold the cells' fields (pass
 * every field). `null` when nothing is written.
 */
export function resolveCells<T>(
  ctx: SheetContext<T>,
  pending: readonly PendingCell[],
  result: ResolveResult
): ChangeSet | null {
  const patches: CellPatch[] = [];
  const rejected: CellRejection[] = [];
  const newOptions: NewOption[] = [];
  const byId = new Map<string, T>();
  for (const record of ctx.records) {
    byId.set(String(ctx.getRecordId(record)), record);
  }
  for (const cell of pending) {
    const field: EuiSheetField<T> | undefined = ctx.fields.find(
      (f) => f.id === cell.fieldId
    );
    if (!field) continue;
    const id: RecordId = cell.recordId ?? cell.tempId!;
    const record = byId.get(String(id));
    const type = resolveType(ctx.types, field);
    const answers = result[cell.fieldId] ?? {};
    const parts = cell.parts.map((text) => ({
      text,
      value: Object.prototype.hasOwnProperty.call(answers, text)
        ? (answers[text] ?? null)
        : null
    }));
    const context = {
      record,
      messages: ctx.messages,
      source: 'paste' as const
    };
    const combined: ParseResult<unknown> = type.resolve
      ? type.resolve.combine(parts, field, context)
      : combineOne(parts, cell.text, ctx as SheetContext<unknown>);
    if (!('value' in combined)) {
      const message =
        'error' in combined
          ? combined.error
          : ctx.messages.unresolved(combined.unresolved);
      rejected.push(
        cell.recordId !== undefined
          ? {
              recordId: cell.recordId,
              fieldId: cell.fieldId,
              text: cell.text,
              message
            }
          : {
              tempId: cell.tempId!,
              fieldId: cell.fieldId,
              text: cell.text,
              message
            }
      );
      continue;
    }
    const from = valueOf(record, cell.fieldId);
    if (!sameFieldValue(type, from, combined.value)) {
      patches.push({
        recordId: id,
        fieldId: cell.fieldId,
        from,
        to: combined.value
      });
    }
    for (const option of [
      ...(combined.newOption ? [combined.newOption] : []),
      ...(combined.newOptions ?? [])
    ]) {
      newOptions.push({ fieldId: cell.fieldId, option });
    }
  }
  if (!patches.length && !rejected.length && !newOptions.length) return null;
  return { source: 'resolve', patches, inserts: [], rejected, newOptions };
}
