/**
 * Finding a few records by id in a large `records` (internal: not exported
 * from the core's index).
 */
import type { RecordId } from './types.ts';

/** A record found by `findRecords`, and its index in `records`. */
export interface FoundRecord<T> {
  record: T;
  row: number;
}

/**
 * The records of the given ids (as `String(getRecordId(record))`) and their
 * indexes, in one pass over `records` that keeps only those: a change set
 * names a few thousand cells at most, `records` may hold 100,000, and a
 * map of every record costs more than the pass. With two records of one
 * id the last one is found, as in `new Map(records.map(...))`.
 *
 * A record's id is looked up as it is, and turned into a string only when
 * it is one of `ids`: `String()` of every numeric id, and hashing each new
 * string, cost ten times the rest of the pass (about 40 ms against 3 ms
 * over 100,000 records in Chromium, the first time).
 */
export function findRecords<T>(
  records: readonly T[],
  getRecordId: (record: T) => RecordId,
  ids: ReadonlySet<string>
): Map<string, FoundRecord<T>> {
  const found = new Map<string, FoundRecord<T>>();
  if (!ids.size) return found;
  // the ids, and the number each numeric one is the string of: a number id
  // is in `keys` exactly when its `String()` is in `ids`
  const keys = new Set<unknown>(ids);
  for (const id of ids) {
    const number = Number(id);
    if (String(number) === id) keys.add(number);
  }
  for (let row = 0; row < records.length; row++) {
    const record = records[row]!;
    const raw: unknown = getRecordId(record);
    const named =
      typeof raw === 'number' || typeof raw === 'string'
        ? keys.has(raw)
        : ids.has(String(raw));
    if (!named) continue;
    const id = String(raw);
    if (ids.has(id)) found.set(id, { record, row });
  }
  return found;
}

/**
 * A test of whether a record's id, as `String(id)`, is one of `ids`,
 * comparing the raw id first (as `findRecords` does): for a pass over many
 * records with few ids, without `String()` of each.
 */
export function namedBy(ids: ReadonlySet<string>): (raw: unknown) => boolean {
  const keys = new Set<unknown>(ids);
  for (const id of ids) {
    const number = Number(id);
    if (String(number) === id) keys.add(number);
  }
  return (raw) =>
    typeof raw === 'number' || typeof raw === 'string'
      ? keys.has(raw)
      : ids.has(String(raw));
}
