/**
 * Undo and redo as change sets: the sheet keeps the change sets it emitted
 * for user actions, and undoing one emits its inverse.
 */
import { valueOf } from './fields.ts';

import type { CellPatch, ChangeSet, RecordId, RecordInsert } from './types.ts';

/**
 * The inverse of a change set (no checks against the records): each patch
 * with `from` and `to` swapped, each insert a deletion of its `tempId`.
 * Source 'undo'; no inserts, rejections or new options.
 */
export function invertChangeSet(changeSet: ChangeSet): ChangeSet {
  return {
    source: 'undo',
    patches: changeSet.patches.map((patch) => ({
      recordId: patch.recordId,
      fieldId: patch.fieldId,
      from: patch.to,
      to: patch.from
    })),
    inserts: [],
    deletes: changeSet.inserts.map((insert) => insert.tempId),
    rejected: [],
    newOptions: []
  };
}

/**
 * The part of a change set that does not overwrite someone else's change
 * (last write wins elsewhere, so this is how undo and redo avoid it):
 *
 * - a patch is kept when its record exists and the cell still holds its
 *   `from` (`Object.is`);
 * - a deletion is kept when the record exists and, given `inserted` (the
 *   inserts being undone), still holds every value its insert set;
 * - an insert is kept when no record has its `tempId` yet (it re-inserts a
 *   row an undo removed), at the end of the records.
 *
 * `null` when nothing is left. `rejected` and `newOptions` are dropped.
 */
export function withoutConflicts<T>(
  changeSet: ChangeSet,
  records: readonly T[],
  getRecordId: (record: T) => RecordId,
  options: { inserted?: readonly RecordInsert[] } = {}
): ChangeSet | null {
  const byId = new Map<string, T>();
  for (const record of records) byId.set(String(getRecordId(record)), record);

  const patches: CellPatch[] = changeSet.patches.filter((patch) => {
    const id = String(patch.recordId);
    return (
      byId.has(id) &&
      Object.is(valueOf(byId.get(id), patch.fieldId), patch.from)
    );
  });

  const deletes: RecordId[] = (changeSet.deletes ?? []).filter((recordId) => {
    const id = String(recordId);
    if (!byId.has(id)) return false;
    const insert = options.inserted?.find((entry) => entry.tempId === id);
    if (!insert) return true;
    const record = byId.get(id);
    return Object.entries(insert.values).every(([fieldId, value]) =>
      Object.is(valueOf(record, fieldId), value)
    );
  });

  const inserts: RecordInsert[] = changeSet.inserts
    .filter((insert) => !byId.has(insert.tempId))
    .map((insert, i) => ({ ...insert, index: records.length + i }));

  if (!patches.length && !deletes.length && !inserts.length) return null;
  const result: ChangeSet = {
    source: changeSet.source,
    patches,
    inserts,
    rejected: [],
    newOptions: []
  };
  if (deletes.length) result.deletes = deletes;
  return result;
}

/**
 * What undoing `entry` (a change set the sheet emitted) writes now: its
 * inverse without the cells changed since. `null` when nothing is left.
 */
export function undoChangeSet<T>(
  entry: ChangeSet,
  records: readonly T[],
  getRecordId: (record: T) => RecordId
): ChangeSet | null {
  return withoutConflicts(invertChangeSet(entry), records, getRecordId, {
    inserted: entry.inserts
  });
}

/**
 * What redoing `entry` writes now: its patches and inserts again (same
 * `tempId`s and values), source 'redo', without the cells changed since the
 * undo. `null` when nothing is left.
 */
export function redoChangeSet<T>(
  entry: ChangeSet,
  records: readonly T[],
  getRecordId: (record: T) => RecordId
): ChangeSet | null {
  return withoutConflicts(
    {
      source: 'redo',
      patches: entry.patches,
      inserts: entry.inserts,
      rejected: [],
      newOptions: []
    },
    records,
    getRecordId
  );
}
