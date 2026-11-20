/**
 * Change-set builders: what an edit, a clear or a paste writes, as plain
 * data the owner applies (PACKAGE-DESIGN.md 5.5).
 */
import { isReadOnly, resolveType, sameFieldValue, valueOf } from './fields.ts';
import { buildPaste } from './paste-plan.ts';

import type { PasteInsert } from './paste-plan.ts';

import type {
  CellPatch,
  ChangeSet,
  EuiSheetField,
  NewOption,
  ParseResult,
  Pos,
  Range,
  RecordId,
  RecordInsert,
  RecordMove,
  RecordRemoval,
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
  const result: ChangeSet = {
    source,
    patches: parts.patches ?? [],
    inserts: parts.inserts ?? [],
    rejected: parts.rejected ?? [],
    newOptions: parts.newOptions ?? []
  };
  if (parts.deletes) result.deletes = parts.deletes;
  if (parts.removed) result.removed = parts.removed;
  if (parts.moves) result.moves = parts.moves;
  return result;
}

function rejectionMessage(
  ctx: SheetContext<unknown>,
  result: ParseResult<unknown>
): string | undefined {
  if ('error' in result) return result.error;
  if ('unresolved' in result) return ctx.messages.unresolved(result.unresolved);
  return undefined;
}

/** The options a parse result creates (`newOption` and `newOptions`). */
function parsedOptions(result: ParseResult<unknown>): NewOption['option'][] {
  if (!('value' in result)) return [];
  const { newOption, newOptions } = result;
  return [...(newOption ? [newOption] : []), ...(newOptions ?? [])];
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
  const type = resolveType(ctx.types, field);
  const result = type.parse(text, field, {
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
  const { value } = result as { value: unknown };
  const from = valueOf(record, field.id);
  if (sameFieldValue(type, from, value)) return null;
  return changeSet('edit', {
    patches: [{ recordId, fieldId: field.id, from, to: value }],
    newOptions: parsedOptions(result).map((option) => ({
      fieldId: field.id,
      option
    }))
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
  if (sameFieldValue(resolveType(ctx.types, field), from, value)) return null;
  return changeSet('edit', {
    patches: [
      { recordId: ctx.getRecordId(record), fieldId: field.id, from, to: value }
    ]
  });
}

/**
 * The type's empty value (`parse('')`) per non-read-only cell whose value
 * differs; `null` when nothing changes. Source 'clear', or `options.source`
 * ('cut': the sheet's cut clears what it copied).
 */
export function clearRange<T>(
  ctx: SheetContext<T>,
  range: Range,
  options: { source?: 'clear' | 'cut' } = {}
): ChangeSet | null {
  const patches: CellPatch[] = [];
  const bottom = Math.min(range.bottom, ctx.records.length - 1);
  const right = Math.min(range.right, ctx.fields.length - 1);
  for (let row = Math.max(range.top, 0); row <= bottom; row++) {
    const record = ctx.records[row]!;
    for (let col = Math.max(range.left, 0); col <= right; col++) {
      const field = ctx.fields[col]!;
      if (isReadOnly(ctx, field, record)) continue;
      const type = resolveType(ctx.types, field);
      const result = type.parse('', field, {
        record,
        messages: ctx.messages,
        source: 'clear'
      });
      if (!('value' in result)) continue;
      const from = valueOf(record, field.id);
      if (sameFieldValue(type, from, result.value)) continue;
      patches.push({
        recordId: ctx.getRecordId(record),
        fieldId: field.id,
        from,
        to: result.value
      });
    }
  }
  return patches.length
    ? changeSet(options.source ?? 'clear', { patches })
    : null;
}

/**
 * Cell `[i][j]` goes to `anchor + (i, j)`. Columns past the last field are
 * dropped, read-only cells skipped (per record). Each row is parsed left to
 * right against the record merged with the values accepted so far in that
 * row. A text the type cannot read gives a rejection instead of a patch.
 * Rows past the end give one insert each when they have at least one
 * accepted or rejected cell; `insert` says where they go and what values
 * and `groupKey` they get (a group's, V03-DESIGN.md 8.5).
 */
export function pasteMatrix<T>(
  ctx: SheetContext<T>,
  anchor: Pos,
  matrix: readonly (readonly string[])[],
  options: { nextTempId?: () => string; insert?: PasteInsert } = {}
): ChangeSet | null {
  return buildPaste(ctx, anchor, matrix, options).changeSet;
}

/**
 * The records with the change set applied (pure). Patched records are new
 * objects, the others keep their identity; records whose id is in `deletes`
 * are removed (compared as strings). Then each insert, in ascending
 * `index`: when its `anchor` is in the array (or is the `tempId` of an
 * insert placed before it in this call), right before or after it; else at
 * `index` (an index past the end appends). An insert with `restore` puts
 * back `restore.record` as it is, unless `restoreRecord` is given.
 * Then each move, in order (V03 4.3): the record is taken out and put
 * back right before or after its anchor; a move without an anchor, or
 * whose record or anchor is not in the array, changes nothing.
 * `rejected` and `newOptions` do not touch records.
 */
export function applyChangeSet<T extends object>(
  records: readonly T[],
  changeSet: ChangeSet,
  options: {
    getRecordId: (record: T) => RecordId;
    /** Default: `{ id: tempId, ...values }`. */
    createRecord?: (values: Record<string, unknown>, tempId: string) => T;
    /** The record an undo of a delete puts back. Default: `insert.restore.record`. */
    restoreRecord?: (insert: RecordInsert) => T;
  }
): T[] {
  const { getRecordId } = options;
  const byId = new Map<RecordId, Record<string, unknown>>();
  for (const patch of changeSet.patches) {
    const values = byId.get(patch.recordId) ?? {};
    values[patch.fieldId] = patch.to;
    byId.set(patch.recordId, values);
  }
  const deleted = new Set((changeSet.deletes ?? []).map(String));
  const kept = deleted.size
    ? records.filter((record) => !deleted.has(String(getRecordId(record))))
    : records;
  const next = kept.map((record) => {
    const values = byId.get(getRecordId(record));
    return values ? ({ ...record, ...values } as T) : record;
  });
  if (changeSet.inserts.length) applyInserts(next, changeSet, options);
  if (changeSet.moves?.length) {
    applyMoves(next, changeSet.moves, (record) => getRecordId(record));
  }
  return next;
}

/** The inserts of `applyChangeSet`, in place. */
function applyInserts<T extends object>(
  next: T[],
  changeSet: ChangeSet,
  options: {
    getRecordId: (record: T) => RecordId;
    createRecord?: (values: Record<string, unknown>, tempId: string) => T;
    restoreRecord?: (insert: RecordInsert) => T;
  }
): void {
  const { getRecordId, createRecord, restoreRecord } = options;

  // tempId → the record this call created for it, whatever its id
  const created = new Map<string, T>();
  // where the previous insert went: the usual anchor of the next one
  let lastAt = -1;
  const indexOf = (anchor: RecordId): number => {
    const record = created.get(String(anchor));
    if (record !== undefined) {
      if (next[lastAt] === record) return lastAt;
      return next.indexOf(record);
    }
    const id = String(anchor);
    for (let i = next.length - 1; i >= 0; i--) {
      if (String(getRecordId(next[i]!)) === id) return i;
    }
    return -1;
  };
  const inserts = [...changeSet.inserts].sort((a, b) => a.index - b.index);
  for (const insert of inserts) {
    let record: T;
    if (insert.restore) {
      record = restoreRecord
        ? restoreRecord(insert)
        : (insert.restore.record as T);
    } else {
      record = createRecord
        ? createRecord(insert.values, insert.tempId)
        : ({ id: insert.tempId, ...insert.values } as unknown as T);
    }
    let at = -1;
    if (insert.anchor) {
      const found = indexOf(insert.anchor.recordId);
      if (found >= 0)
        at = insert.anchor.position === 'after' ? found + 1 : found;
    }
    if (at < 0) at = Math.min(Math.max(insert.index, 0), next.length);
    next.splice(at, 0, record);
    created.set(insert.tempId, record);
    lastAt = at;
  }
}

/**
 * The moves of a change set, in place, in order: each record is taken out
 * and put back next to its anchor. Skipped: no anchor, the record or the
 * anchor not found, the anchor being the record itself.
 */
function applyMoves<I>(
  items: I[],
  moves: readonly RecordMove[],
  idOf: (item: I) => RecordId
): void {
  const find = (id: RecordId): number => {
    const wanted = String(id);
    return items.findIndex((item) => String(idOf(item)) === wanted);
  };
  for (const move of moves) {
    if (!move.anchor) continue;
    if (String(move.anchor.recordId) === String(move.recordId)) continue;
    const from = find(move.recordId);
    if (from < 0) continue;
    const [item] = items.splice(from, 1);
    const anchor = find(move.anchor.recordId);
    if (anchor < 0) {
      items.splice(from, 0, item!);
      continue;
    }
    items.splice(
      move.anchor.position === 'after' ? anchor + 1 : anchor,
      0,
      item!
    );
  }
}

/** Where a row drag (or `SheetApi.moveRecords`) puts records: options of `moveRecords`. */
export interface MoveRecordsOptions {
  /**
   * With `@groups`: the group the records land in. `start` and `end` are
   * the record indexes of its loaded records (`end` exclusive; equal for a
   * collapsed or empty group): the anchor is one of them. `values` are the
   * group's values (each level's field), patched on records that come
   * from another group.
   */
  group?: {
    key: string;
    start: number;
    end: number;
    values?: Record<string, unknown>;
  };
  /** With `@groups`: the key of the group the record at this index is in. */
  groupKeyOf?: (index: number) => string | undefined;
  /** Value equality for the group patches. Default `Object.is`. */
  equals?: (fieldId: string, a: unknown, b: unknown) => boolean;
}

/**
 * The move of records next to a target (pure, V03 4.3, 10.1): one
 * `RecordMove` per record, in their order in `ctx.records`. The first is
 * anchored to the record that does not move nearest the target (before it
 * when one is there, else after it; inside `group` when given), each next
 * one after the previous. `target` is a record of `ctx.records` (it may be
 * one of the moved ones); absent, the end of `group` (or of the records).
 * Into a group with no other loaded record the moves have no anchor, only
 * `groupKey`. Records from another group get patches to the group's
 * values. Source 'move'. `null` when nothing would change, or a target or
 * every id is not found.
 */
export function moveRecords<T>(
  ctx: Pick<SheetContext<T>, 'records' | 'getRecordId'>,
  ids: readonly RecordId[],
  target: RecordMove['anchor'] | undefined,
  options: MoveRecordsOptions = {}
): ChangeSet | null {
  const records = ctx.records;
  const idOf = (index: number) => ctx.getRecordId(records[index]!);
  const wanted = new Set(ids.map(String));
  const indexes: number[] = [];
  records.forEach((record, index) => {
    if (wanted.has(String(ctx.getRecordId(record)))) indexes.push(index);
  });
  if (!indexes.length) return null;
  const moving = new Set(indexes);
  const group = options.group;
  let gap: number;
  if (target) {
    const at = records.findIndex(
      (record) => String(ctx.getRecordId(record)) === String(target.recordId)
    );
    if (at < 0) return null;
    gap = target.position === 'after' ? at + 1 : at;
  } else {
    gap = group ? group.end : records.length;
  }
  const start = group ? Math.max(0, group.start) : 0;
  const end = group ? Math.min(records.length, group.end) : records.length;
  gap = Math.min(Math.max(gap, start), end);
  let anchor: RecordMove['anchor'];
  for (let i = gap - 1; i >= start && !anchor; i--) {
    if (!moving.has(i)) anchor = { recordId: idOf(i), position: 'after' };
  }
  for (let i = gap; i < end && !anchor; i++) {
    if (!moving.has(i)) anchor = { recordId: idOf(i), position: 'before' };
  }
  // every record moves, and no group to land in: nothing to place them by
  if (!anchor && !group) return null;

  const moves: RecordMove[] = indexes.map((index, k) => {
    const move: RecordMove = { recordId: idOf(index), from: {} };
    if (index > 0) move.from.after = idOf(index - 1);
    const fromKey = options.groupKeyOf?.(index);
    if (fromKey !== undefined) move.from.groupKey = fromKey;
    const to =
      k === 0
        ? anchor
        : { recordId: idOf(indexes[k - 1]!), position: 'after' as const };
    if (to) move.anchor = to;
    if (group) move.groupKey = group.key;
    return move;
  });

  const patches: CellPatch[] = [];
  const equals = options.equals ?? ((_id, a, b) => Object.is(a, b));
  if (group?.values) {
    for (const index of indexes) {
      if (options.groupKeyOf?.(index) === group.key) continue;
      const record = records[index];
      for (const [fieldId, to] of Object.entries(group.values)) {
        const from = valueOf(record, fieldId);
        if (equals(fieldId, from, to)) continue;
        patches.push({ recordId: idOf(index), fieldId, from, to });
      }
    }
  }

  const before = records.map((record) => String(ctx.getRecordId(record)));
  const after = [...before];
  applyMoves(after, moves, (id) => id);
  const sameOrder = after.every((id, i) => id === before[i]);
  const sameGroups = moves.every(
    (move) =>
      move.groupKey === undefined || move.groupKey === move.from.groupKey
  );
  if (sameOrder && sameGroups && !patches.length) return null;
  return changeSet('move', { patches, moves });
}

/**
 * Inserts new records (pure): one per entry of `values` (default one
 * empty record), at indexes `at`, `at + 1`, ...; the first has `anchor`,
 * each next one is anchored after the previous `tempId`. Source 'insert'.
 * The values are not parsed or checked.
 */
export function insertRecords<T>(
  _ctx: SheetContext<T>,
  options: {
    at: number;
    anchor?: RecordInsert['anchor'];
    values?: Record<string, unknown>[];
    nextTempId?: () => string;
    /** The group every insert goes into (V03 8.4): set on each `RecordInsert`. */
    groupKey?: string;
  }
): ChangeSet {
  const values = options.values?.length ? options.values : [{}];
  const inserts: RecordInsert[] = [];
  values.forEach((entry, i) => {
    const insert: RecordInsert = {
      tempId: options.nextTempId?.() ?? `new-${i}`,
      index: options.at + i,
      values: { ...entry }
    };
    if (options.groupKey !== undefined) insert.groupKey = options.groupKey;
    const previous = inserts[i - 1];
    const anchor = previous
      ? { recordId: previous.tempId, position: 'after' as const }
      : options.anchor;
    if (anchor) insert.anchor = anchor;
    inserts.push(insert);
  });
  return changeSet('insert', { inserts });
}

/**
 * Removes records by id (pure): `deletes` and `removed` (what an undo
 * needs to put them back) in ascending index. Ids that match no record are
 * dropped; `null` when none is left. Source 'delete'.
 */
export function deleteRecords<T>(
  records: readonly T[],
  ids: readonly RecordId[],
  getRecordId: (record: T) => RecordId
): ChangeSet | null {
  const wanted = new Set(ids.map(String));
  const removed: RecordRemoval[] = [];
  records.forEach((record, index) => {
    const recordId = getRecordId(record);
    if (!wanted.has(String(recordId))) return;
    const removal: RecordRemoval = { recordId, index, record };
    const before = records[index - 1];
    if (before !== undefined) removal.after = getRecordId(before);
    removed.push(removal);
  });
  if (!removed.length) return null;
  return changeSet('delete', {
    deletes: removed.map((removal) => removal.recordId),
    removed
  });
}

/**
 * A copy of each listed record right after it (pure): its value for every
 * field of `ctx.fields` that is not read-only for that record (pass every
 * field, visible and hidden). Indexes that match no record are dropped;
 * `null` when none is left. Source 'insert'.
 */
export function duplicateRecords<T>(
  ctx: SheetContext<T>,
  recordIndexes: readonly number[],
  options: {
    nextTempId?: () => string;
    /**
     * The group a copy of the record at this index goes into (V03 8.4):
     * its values win over the copied ones, and `groupKey` is set.
     */
    group?: (
      index: number
    ) => { values: Record<string, unknown>; groupKey: string } | undefined;
  } = {}
): ChangeSet | null {
  const indexes = [...new Set(recordIndexes)]
    .filter((index) => ctx.records[index] !== undefined)
    .sort((a, b) => a - b);
  const inserts: RecordInsert[] = indexes.map((index, i) => {
    const record = ctx.records[index]!;
    const values: Record<string, unknown> = {};
    for (const field of ctx.fields) {
      if (isReadOnly(ctx, field, record)) continue;
      const value = valueOf(record, field.id);
      if (value !== undefined) values[field.id] = value;
    }
    const insert: RecordInsert = {
      tempId: options.nextTempId?.() ?? `new-${i}`,
      // each earlier copy is one more row before this one
      index: index + 1 + i,
      values,
      anchor: { recordId: ctx.getRecordId(record), position: 'after' }
    };
    const group = options.group?.(index);
    if (group) {
      Object.assign(values, group.values);
      insert.groupKey = group.groupKey;
    }
    return insert;
  });
  return inserts.length ? changeSet('insert', { inserts }) : null;
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
