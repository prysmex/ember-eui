/**
 * `SheetApi.remapIds`: the ids an owner gave to inserted (or restored)
 * records, applied to the change sets the sheet keeps (V02-DESIGN.md 3.6).
 * Plain TypeScript.
 */
import type { ChangeSet, RecordId } from '../core/index.ts';

/** Old id (as a string) → the owner's id. */
export type IdMap = ReadonlyMap<string, RecordId>;

/** `ids` as a map; an entry whose id does not change is left out. */
export function toIdMap(ids: Record<string, RecordId>): Map<string, RecordId> {
  const map = new Map<string, RecordId>();
  for (const [from, to] of Object.entries(ids)) {
    if (String(to) !== from) map.set(from, to);
  }
  return map;
}

/** `current` with `next` applied after it: a → b then b → c gives a → c. */
export function composeIdMaps(
  current: IdMap,
  next: IdMap
): Map<string, RecordId> {
  const result = new Map<string, RecordId>();
  for (const [from, to] of current)
    result.set(from, next.get(String(to)) ?? to);
  for (const [from, to] of next) if (!result.has(from)) result.set(from, to);
  return result;
}

export function remapId(id: RecordId, ids: IdMap): RecordId {
  return ids.get(String(id)) ?? id;
}

/**
 * The change set with every record id it names remapped: patches, inserts
 * (`tempId`, `anchor`, `restore`), deletes, removed (`recordId`, `after`)
 * and rejections (a rejection on a `tempId` becomes one on the record).
 * The same object when nothing changes.
 */
export function remapChangeSet(changeSet: ChangeSet, ids: IdMap): ChangeSet {
  if (!ids.size) return changeSet;
  let changed = false;
  const id = (value: RecordId): RecordId => {
    const next = remapId(value, ids);
    if (next !== value) changed = true;
    return next;
  };
  const result: ChangeSet = {
    ...changeSet,
    patches: changeSet.patches.map((patch) => ({
      ...patch,
      recordId: id(patch.recordId)
    })),
    inserts: changeSet.inserts.map((insert) => {
      const next = { ...insert, tempId: String(id(insert.tempId)) };
      if (insert.anchor) {
        next.anchor = {
          ...insert.anchor,
          recordId: id(insert.anchor.recordId)
        };
      }
      if (insert.restore) {
        next.restore = {
          ...insert.restore,
          recordId: id(insert.restore.recordId)
        };
      }
      return next;
    }),
    rejected: changeSet.rejected.map((rejection) => {
      if (rejection.tempId !== undefined && ids.has(rejection.tempId)) {
        changed = true;
        const { tempId, ...rest } = rejection;
        return { ...rest, recordId: ids.get(tempId)! };
      }
      if (rejection.recordId === undefined) return rejection;
      return { ...rejection, recordId: id(rejection.recordId) };
    })
  };
  if (changeSet.deletes) result.deletes = changeSet.deletes.map(id);
  if (changeSet.removed) {
    result.removed = changeSet.removed.map((removal) => {
      const next = { ...removal, recordId: id(removal.recordId) };
      if (removal.after !== undefined) next.after = id(removal.after);
      return next;
    });
  }
  return changed ? result : changeSet;
}
