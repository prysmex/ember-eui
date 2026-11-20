/**
 * Undo and redo as change sets: the sheet keeps the change sets it emitted
 * for user actions, and undoing one emits its inverse.
 */
import { valueOf } from './fields.ts';

import type {
  CellPatch,
  ChangeSet,
  RecordId,
  RecordInsert,
  RecordMove,
  RecordRemoval
} from './types.ts';

/** Compares a cell's value with the value a change left there. Default `Object.is`. */
export type ValueEquals = (fieldId: string, a: unknown, b: unknown) => boolean;

const sameValue: ValueEquals = (_fieldId, a, b) => Object.is(a, b);

/**
 * The inverse of a change set (no checks against the records): each patch
 * with `from` and `to` swapped, each insert a deletion of its `tempId`, and
 * each `removed` record an insert that puts it back (`restore`), at its old
 * index and after its old neighbour, in ascending index. A restore's
 * `values` are the record's values for `fieldIds` (none without them).
 * Each move becomes the move back, in the same order (not reversed: a
 * row's `from.after` may be an earlier moved row, put back by then):
 * after `from.after`, or, for a record that was first, before the first
 * of `order` (the record ids now; without it such a move has no anchor).
 * Source 'undo'; no rejections or new options.
 */
export function invertChangeSet(
  changeSet: ChangeSet,
  fieldIds?: readonly string[],
  order?: readonly RecordId[]
): ChangeSet {
  const inserts: RecordInsert[] = [...(changeSet.removed ?? [])]
    .sort((a, b) => a.index - b.index)
    .map((removal) => {
      const values: Record<string, unknown> = {};
      for (const fieldId of fieldIds ?? []) {
        const value = valueOf(removal.record, fieldId);
        if (value !== undefined) values[fieldId] = value;
      }
      const insert: RecordInsert = {
        tempId: String(removal.recordId),
        index: removal.index,
        values,
        restore: { recordId: removal.recordId, record: removal.record }
      };
      if (removal.after !== undefined) {
        insert.anchor = { recordId: removal.after, position: 'after' };
      }
      return insert;
    });
  const result: ChangeSet = {
    source: 'undo',
    patches: changeSet.patches.map((patch) => ({
      recordId: patch.recordId,
      fieldId: patch.fieldId,
      from: patch.to,
      to: patch.from
    })),
    inserts,
    deletes: changeSet.inserts.map((insert) => insert.tempId),
    rejected: [],
    newOptions: []
  };
  if (changeSet.moves?.length) {
    result.moves = changeSet.moves.map((move) => invertMove(move, order));
  }
  return result;
}

/** The move back of one move (`invertChangeSet`). Its `from` is where the record is now. */
function invertMove(
  move: RecordMove,
  order: readonly RecordId[] | undefined
): RecordMove {
  const back: RecordMove = { recordId: move.recordId, from: {} };
  if (move.from.after !== undefined) {
    back.anchor = { recordId: move.from.after, position: 'after' };
  } else if (order?.length) {
    back.anchor = { recordId: order[0]!, position: 'before' };
  }
  if (move.from.groupKey !== undefined) back.groupKey = move.from.groupKey;
  if (order) {
    const at = order.findIndex((id) => String(id) === String(move.recordId));
    if (at > 0) back.from.after = order[at - 1];
  } else if (move.anchor?.position === 'after') {
    back.from.after = move.anchor.recordId;
  }
  if (move.groupKey !== undefined) back.from.groupKey = move.groupKey;
  return back;
}

/**
 * The part of a change set that does not overwrite someone else's change
 * (last write wins elsewhere, so this is how undo and redo avoid it):
 *
 * - a patch is kept when its record exists and the cell still holds its
 *   `from` (`equals`, default `Object.is`); with `keepUnseen`, a patch of
 *   a record that is not in `records` is kept too, unchecked (V03 8.5: a
 *   record in a collapsed group, which the owner still has);
 * - a deletion is kept when the record exists and, given `inserted` (the
 *   inserts being undone), still holds every value its insert set;
 * - an insert is kept when no record has its `tempId` (or its restored
 *   record's id) yet. It keeps its position: right after (or before) its
 *   anchor's current index when the anchor exists, else `index`, clamped
 *   to the end;
 * - a move is kept when its record exists (or, with `keepUnseen`, always).
 *
 * `removed` follows the kept deletions. `null` when nothing is left.
 * `rejected` and `newOptions` are dropped.
 */
export function withoutConflicts<T>(
  changeSet: ChangeSet,
  records: readonly T[],
  getRecordId: (record: T) => RecordId,
  options: {
    inserted?: readonly RecordInsert[];
    equals?: ValueEquals;
    keepUnseen?: boolean;
  } = {}
): ChangeSet | null {
  const equals = options.equals ?? sameValue;
  const byId = new Map<string, T>();
  for (const record of records) byId.set(String(getRecordId(record)), record);

  const patches: CellPatch[] = changeSet.patches.filter((patch) => {
    const id = String(patch.recordId);
    if (!byId.has(id)) return !!options.keepUnseen;
    return equals(
      patch.fieldId,
      valueOf(byId.get(id), patch.fieldId),
      patch.from
    );
  });

  const deletes: RecordId[] = (changeSet.deletes ?? []).filter((recordId) => {
    const id = String(recordId);
    if (!byId.has(id)) return false;
    const insert = options.inserted?.find((entry) => entry.tempId === id);
    if (!insert) return true;
    const record = byId.get(id);
    return Object.entries(insert.values).every(([fieldId, value]) =>
      equals(fieldId, valueOf(record, fieldId), value)
    );
  });

  const inserts = placeInserts(
    changeSet.inserts.filter(
      (insert) =>
        !byId.has(insert.tempId) &&
        !(insert.restore && byId.has(String(insert.restore.recordId)))
    ),
    records.map((record) => String(getRecordId(record)))
  );

  const moves = (changeSet.moves ?? []).filter(
    (move) => options.keepUnseen || byId.has(String(move.recordId))
  );

  if (!patches.length && !deletes.length && !inserts.length && !moves.length) {
    return null;
  }
  const result: ChangeSet = {
    source: changeSet.source,
    patches,
    inserts,
    rejected: [],
    newOptions: []
  };
  if (deletes.length) result.deletes = deletes;
  if (moves.length) result.moves = moves;
  if (changeSet.removed && deletes.length) {
    const kept = new Set(deletes.map(String));
    const removed = changeSet.removed.filter((removal: RecordRemoval) =>
      kept.has(String(removal.recordId))
    );
    if (removed.length) result.removed = removed;
  }
  return result;
}

/**
 * The inserts (ascending `index`) with the index each gets now, placed as
 * `applyChangeSet` places them over records with these ids: after (or
 * before) the anchor when it exists or was placed earlier, else at `index`
 * clamped to the end.
 */
function placeInserts(
  inserts: readonly RecordInsert[],
  ids: string[]
): RecordInsert[] {
  let lastAt = -1;
  return [...inserts]
    .sort((a, b) => a.index - b.index)
    .map((insert) => {
      let at = -1;
      if (insert.anchor) {
        const anchor = String(insert.anchor.recordId);
        const found = ids[lastAt] === anchor ? lastAt : ids.lastIndexOf(anchor);
        if (found >= 0) {
          at = insert.anchor.position === 'after' ? found + 1 : found;
        }
      }
      if (at < 0) at = Math.min(Math.max(insert.index, 0), ids.length);
      ids.splice(at, 0, insert.tempId);
      lastAt = at;
      return { ...insert, index: at };
    });
}

/** Options of `undoChangeSet` and `redoChangeSet`. */
export interface HistoryOptions {
  /** Every field id (visible and hidden): the values a restored record's insert lists. */
  fieldIds?: readonly string[];
  /** How a cell's value is compared with the value the change left there. Default `Object.is`. */
  equals?: ValueEquals;
  /**
   * Patches of records that are not in `records` are kept, without the
   * "changed since" check (V03 8.5: grouped, such a record is in a
   * collapsed group and the owner still has it). Default false: dropped.
   */
  keepUnseen?: boolean;
}

/**
 * What undoing `entry` (a change set the sheet emitted) writes now: its
 * inverse without the cells changed since. `null` when nothing is left.
 */
export function undoChangeSet<T>(
  entry: ChangeSet,
  records: readonly T[],
  getRecordId: (record: T) => RecordId,
  options: HistoryOptions = {}
): ChangeSet | null {
  return withoutConflicts(
    invertChangeSet(
      entry,
      options.fieldIds,
      entry.moves?.length ? records.map(getRecordId) : undefined
    ),
    records,
    getRecordId,
    {
      inserted: entry.inserts,
      equals: options.equals,
      keepUnseen: options.keepUnseen
    }
  );
}

/**
 * What redoing `entry` writes now: its patches, inserts (same `tempId`s and
 * values), deletes and `removed` again, source 'redo', without the cells
 * changed since the undo. `null` when nothing is left.
 */
export function redoChangeSet<T>(
  entry: ChangeSet,
  records: readonly T[],
  getRecordId: (record: T) => RecordId,
  options: HistoryOptions = {}
): ChangeSet | null {
  const redo: ChangeSet = {
    source: 'redo',
    patches: entry.patches,
    inserts: entry.inserts,
    rejected: [],
    newOptions: []
  };
  if (entry.deletes) redo.deletes = entry.deletes;
  if (entry.removed) redo.removed = entry.removed;
  if (entry.moves) redo.moves = entry.moves;
  return withoutConflicts(redo, records, getRecordId, {
    equals: options.equals,
    keepUnseen: options.keepUnseen
  });
}

/**
 * Two change sets as one history entry (a paste and the bulk resolve it
 * asked for): patches of the same cell collapse to `first.from` →
 * `second.to`; a patch of `second` on a record `first` inserts is folded
 * into that insert's `values`; inserts, deletes, removed, moves,
 * rejections and new options are concatenated. Source of `first`.
 */
export function mergeChangeSets(
  first: ChangeSet,
  second: ChangeSet
): ChangeSet {
  const inserts = first.inserts.map((insert) => ({
    ...insert,
    values: { ...insert.values }
  }));
  const insertById = new Map(inserts.map((insert) => [insert.tempId, insert]));
  const patches = first.patches.map((patch) => ({ ...patch }));
  const patchByCell = new Map(
    patches.map((patch) => [cellOf(patch), patch] as const)
  );
  for (const patch of second.patches) {
    const insert = insertById.get(String(patch.recordId));
    if (insert) {
      insert.values[patch.fieldId] = patch.to;
      continue;
    }
    const existing = patchByCell.get(cellOf(patch));
    if (existing) {
      existing.to = patch.to;
      continue;
    }
    const copy = { ...patch };
    patches.push(copy);
    patchByCell.set(cellOf(copy), copy);
  }
  const result: ChangeSet = {
    source: first.source,
    patches,
    inserts: [...inserts, ...second.inserts],
    rejected: [...first.rejected, ...second.rejected],
    newOptions: [...first.newOptions, ...second.newOptions]
  };
  const deletes = [...(first.deletes ?? []), ...(second.deletes ?? [])];
  if (deletes.length) result.deletes = deletes;
  const removed = [...(first.removed ?? []), ...(second.removed ?? [])];
  if (removed.length) result.removed = removed;
  const moves = [...(first.moves ?? []), ...(second.moves ?? [])];
  if (moves.length) result.moves = moves;
  return result;
}

function cellOf(patch: CellPatch): string {
  return JSON.stringify([String(patch.recordId), patch.fieldId]);
}

/**
 * A history entry without one field (V03 6.6): its patches, rejections and
 * new options dropped, and its inserts' values without the field (undo
 * checks every value an insert set, so a stale one would keep the insert
 * from being undone). Deletes and moves are kept. `null` when nothing is left; the
 * same object when the entry never touched the field. For a field the
 * owner deleted or retyped: the sheet cannot undo field operations, so its
 * history must not write the field's old values back.
 */
export function withoutField(
  entry: ChangeSet,
  fieldId: string
): ChangeSet | null {
  const touches =
    entry.patches.some((patch) => patch.fieldId === fieldId) ||
    entry.inserts.some((insert) => fieldId in insert.values) ||
    entry.rejected.some((rejection) => rejection.fieldId === fieldId) ||
    entry.newOptions.some((option) => option.fieldId === fieldId);
  if (!touches) return entry;
  const patches = entry.patches.filter((patch) => patch.fieldId !== fieldId);
  const inserts = entry.inserts.map((insert) => {
    if (!(fieldId in insert.values)) return insert;
    const values = { ...insert.values };
    delete values[fieldId];
    return { ...insert, values };
  });
  if (
    !patches.length &&
    !inserts.length &&
    !entry.deletes?.length &&
    !entry.moves?.length
  ) {
    return null;
  }
  return {
    ...entry,
    patches,
    inserts,
    rejected: entry.rejected.filter(
      (rejection) => rejection.fieldId !== fieldId
    ),
    newOptions: entry.newOptions.filter((option) => option.fieldId !== fieldId)
  };
}
