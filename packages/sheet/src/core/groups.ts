/**
 * Group by, outside the component (V03-DESIGN.md 8.7, 8.8): plain
 * TypeScript helpers for an owner that builds `@groups` itself.
 *
 * - `groupRecords`: for an owner that has every record (a local store).
 * - `applyChangeSetToGroups`: keeps `count` and `loaded` right after a
 *   change set, until the owner's next query.
 * - `pageGroups`: for an owner that pages: the backend's headers and one
 *   page of records give the headers of that page.
 *
 * The sheet never calls them: it draws the `@groups` it is given.
 */
import { isEmptyValue, resolveType, valueOf } from './fields.ts';
import { summarize } from './summary.ts';

import type { SheetSummaryKind } from './summary.ts';
import type {
  ChangeSet,
  EuiSheetField,
  FieldType,
  RecordId,
  SheetContext,
  SheetGroup,
  SheetGroupBy
} from './types.ts';

export interface GroupRecordsOptions<T> {
  groupBy: readonly SheetGroupBy[];
  /** To find each level's field and its type. A level whose field is not here is left out. */
  fields: readonly EuiSheetField<T>[];
  /** Keys of the collapsed groups. */
  collapsed?: ReadonlySet<string>;
  /** Per field id, the summary to compute for every group (`summarize`). */
  summaries?: Readonly<Record<string, SheetSummaryKind>>;
  /** Row numbers start after this many records (paged data). Default 0. */
  rowNumberOffset?: number;
}

interface Level<T> {
  by: SheetGroupBy;
  field: EuiSheetField<T>;
  type: FieldType<any, any>;
}

interface Bucket<T> {
  text: string;
  value: unknown;
  records: T[];
}

/**
 * The records grouped by each level's value (V03 8.7).
 *
 * Two values are the same group when the type's `copyText` (else `format`)
 * gives the same text. Groups are ordered by the type's `compare` (else by
 * that text), reversed for `'desc'`; ties keep the order they first
 * appeared in. Inside a group the input order is kept. A key is
 * `field:text`, joined with `/` per level (`status:Open/owner:Ana`).
 *
 * Returns the records of the expanded groups in display order and every
 * header (depth-first) with `count`, `loaded`, `rowNumberStart`,
 * `collapsed` and `summary`. A parent has no `loaded`. `label` is left to
 * the sheet's default. Without a usable level: the records as they are and
 * no groups.
 *
 * It is for an owner that has every record; one that pages gets its groups
 * from its backend and must not call it on a page.
 */
export function groupRecords<T>(
  ctx: Pick<SheetContext<T>, 'types' | 'messages'>,
  records: readonly T[],
  options: GroupRecordsOptions<T>
): { records: T[]; groups: SheetGroup[] } {
  const levels: Level<T>[] = [];
  for (const by of options.groupBy) {
    const field = options.fields.find((candidate) => candidate.id === by.field);
    if (field) levels.push({ by, field, type: resolveType(ctx.types, field) });
  }
  if (!levels.length) return { records: [...records], groups: [] };

  const collapsed = options.collapsed;
  const summaryFields: Array<[EuiSheetField<T>, SheetSummaryKind]> = [];
  for (const [fieldId, kind] of Object.entries(options.summaries ?? {})) {
    const field = options.fields.find((candidate) => candidate.id === fieldId);
    if (field) summaryFields.push([field, kind]);
  }

  const out: T[] = [];
  const groups: SheetGroup[] = [];
  // records seen so far in display order, collapsed groups' included
  let seen = options.rowNumberOffset ?? 0;

  const textOf = (level: Level<T>, record: T): string => {
    const value = valueOf(record, level.field.id);
    if (isEmptyValue(level.type, value)) return '';
    const context = { record, messages: ctx.messages };
    return String(
      level.type.copyText
        ? level.type.copyText(value, level.field, context)
        : level.type.format(value, level.field, context)
    );
  };

  const buckets = (level: Level<T>, items: readonly T[]): Bucket<T>[] => {
    const byText = new Map<string, Bucket<T>>();
    for (const record of items) {
      const text = textOf(level, record);
      let bucket = byText.get(text);
      if (!bucket) {
        const value = valueOf(record, level.field.id);
        bucket = {
          text,
          value: isEmptyValue(level.type, value) ? null : value,
          records: []
        };
        byText.set(text, bucket);
      }
      bucket.records.push(record);
    }
    const sign = level.by.direction === 'desc' ? -1 : 1;
    const list = [...byText.values()];
    const order = new Map(list.map((bucket, i) => [bucket, i]));
    return list.sort((a, b) => {
      const byCompare = level.type.compare
        ? level.type.compare(a.value, b.value, level.field)
        : a.text.localeCompare(b.text);
      if (byCompare) return sign * byCompare;
      // equal under `compare` but different text: text, then first seen
      return (
        sign * a.text.localeCompare(b.text) || order.get(a)! - order.get(b)!
      );
    });
  };

  const walk = (items: readonly T[], depth: number, parentKey: string) => {
    const level = levels[depth]!;
    for (const bucket of buckets(level, items)) {
      const key =
        (parentKey ? `${parentKey}/` : '') + `${level.field.id}:${bucket.text}`;
      const group: SheetGroup = {
        key,
        depth,
        value: bucket.value,
        count: bucket.records.length,
        rowNumberStart: seen + 1
      };
      groups.push(group);
      if (summaryFields.length) {
        const summary: Record<string, string> = {};
        for (const [field, kind] of summaryFields) {
          summary[field.id] = summarize(ctx, bucket.records, field, kind);
        }
        group.summary = summary;
      }
      if (collapsed?.has(key)) {
        group.collapsed = true;
        if (depth === levels.length - 1) group.loaded = 0;
        seen += bucket.records.length;
      } else if (depth === levels.length - 1) {
        group.loaded = bucket.records.length;
        out.push(...bucket.records);
        seen += bucket.records.length;
      } else {
        walk(bucket.records, depth + 1, key);
      }
    }
  };
  walk(records, 0, '');
  return { records: out, groups };
}

/* Keeping the groups right after a change set */

/** The group each loaded record is under (by position), and the ancestors of a group. */
function indexGroups(
  groups: readonly SheetGroup[],
  records: readonly unknown[],
  getRecordId: (record: any) => RecordId
) {
  const groupOf = new Map<string, number>();
  let cursor = 0;
  groups.forEach((group, i) => {
    const loaded = Math.max(0, Math.floor(group.loaded ?? 0));
    for (let n = 0; n < loaded && cursor < records.length; n++) {
      groupOf.set(String(getRecordId(records[cursor++])), i);
    }
  });
  // records past Σ loaded sit in the last group (the sheet draws them there)
  const last = groups.length - 1;
  while (last >= 0 && cursor < records.length) {
    groupOf.set(String(getRecordId(records[cursor++])), last);
  }
  const byKey = new Map(groups.map((group, i) => [group.key, i]));
  const chain = (index: number): number[] => {
    const result = [index];
    let depth = groups[index]!.depth;
    for (let i = index - 1; i >= 0 && depth > 0; i--) {
      if (groups[i]!.depth < depth) {
        depth = groups[i]!.depth;
        result.push(i);
      }
    }
    return result;
  };
  return { groupOf, byKey, chain };
}

/**
 * The groups after a change set (V03 8.7), until the owner's next query.
 * `records` are the records the groups describe (before the change set).
 *
 * - An insert adds one to `count` and `loaded` of its `groupKey` (else of
 *   its anchor's group) and one to `count` of that group's ancestors. A
 *   collapsed group gets `count` only.
 * - A delete subtracts the same from the group the record is under.
 * - A move does both: it leaves its `from.groupKey` (else the group it is
 *   under) and enters its `groupKey` (else its anchor's group).
 * - Patches change nothing: positions stay until the owner re-queries.
 *
 * Returns the same array when nothing changed; groups it does not touch
 * keep their identity.
 */
export function applyChangeSetToGroups(
  groups: readonly SheetGroup[],
  records: readonly unknown[],
  changeSet: ChangeSet,
  getRecordId: (record: any) => RecordId
): SheetGroup[] {
  const inserts = changeSet.inserts;
  const deletes = changeSet.deletes ?? [];
  const moves = changeSet.moves ?? [];
  if (!groups.length || !(inserts.length || deletes.length || moves.length)) {
    return groups as SheetGroup[];
  }
  const { groupOf, byKey, chain } = indexGroups(groups, records, getRecordId);
  // index → [count change, loaded change]
  const delta = new Map<number, [number, number]>();
  const bump = (index: number, loaded: boolean, by: 1 | -1) => {
    const [first, ...ancestors] = chain(index);
    const own = delta.get(first!) ?? [0, 0];
    own[0] += by;
    if (loaded && !groups[first!]!.collapsed) own[1] += by;
    delta.set(first!, own);
    for (const parent of ancestors) {
      const entry = delta.get(parent) ?? [0, 0];
      entry[0] += by;
      delta.set(parent, entry);
    }
  };
  const groupAt = (
    groupKey: string | undefined,
    anchor: { recordId: RecordId } | undefined
  ): number | undefined => {
    if (groupKey !== undefined) return byKey.get(groupKey);
    if (anchor) return groupOf.get(String(anchor.recordId));
    return undefined;
  };

  for (const id of deletes) {
    const at = groupOf.get(String(id));
    if (at === undefined) continue;
    bump(at, true, -1);
    groupOf.delete(String(id));
  }
  for (const insert of inserts) {
    const at = groupAt(insert.groupKey, insert.anchor);
    if (at === undefined) continue;
    bump(at, true, 1);
    groupOf.set(String(insert.tempId), at);
  }
  for (const move of moves) {
    const from =
      move.from.groupKey !== undefined
        ? byKey.get(move.from.groupKey)
        : groupOf.get(String(move.recordId));
    const to = groupAt(move.groupKey, move.anchor) ?? from;
    if (from === undefined || to === undefined || from === to) continue;
    bump(from, true, -1);
    bump(to, true, 1);
    groupOf.set(String(move.recordId), to);
  }

  let changed = false;
  const next = groups.map((group, i) => {
    const change = delta.get(i);
    if (!change || (!change[0] && !change[1])) return group;
    changed = true;
    const result: SheetGroup = {
      ...group,
      count: Math.max(0, group.count + change[0])
    };
    if (change[1] || group.loaded !== undefined) {
      result.loaded = Math.max(0, (group.loaded ?? 0) + change[1]);
    }
    return result;
  });
  return changed ? next : (groups as SheetGroup[]);
}

/* Paged owners */

/**
 * The headers of one page (V03 8.8), for an owner whose backend gives the
 * groups of the whole result with their `count` and the page's records.
 * `groups` is every header, depth-first, as the backend returns it
 * (collapsed groups have no records and no children); the data it pages
 * is the records of the expanded leaf groups, in that order. `groupKeyOf`
 * gives the key of the group a record is directly under.
 *
 * Fills `loaded` (the page's records under each leaf) and `continued` (its
 * first records are not the group's first: the group began on an earlier
 * page, found from `offset`, the position of the page's first record in
 * the data). Leaves the page does not touch are left out, with their
 * ancestors kept; a collapsed group is kept when it sits inside the page
 * (at its start, or at the end of the last page). `rowNumberStart` is not
 * set.
 */
export function pageGroups<T>(
  records: readonly T[],
  groups: readonly SheetGroup[],
  groupKeyOf: (record: T) => string | undefined,
  options: { offset?: number } = {}
): SheetGroup[] {
  const offset = Math.max(0, options.offset ?? 0);
  const end = offset + records.length;
  const onPage = new Map<string, number>();
  for (const record of records) {
    const key = groupKeyOf(record);
    if (key !== undefined) onPage.set(key, (onPage.get(key) ?? 0) + 1);
  }
  const isLeaf = (i: number): boolean =>
    !(groups[i + 1] && groups[i + 1]!.depth > groups[i]!.depth);
  const total = groups.reduce(
    (sum, group, i) =>
      sum + (isLeaf(i) && !group.collapsed ? Math.max(0, group.count) : 0),
    0
  );
  const keep = new Set<number>();
  const patched = new Map<number, SheetGroup>();
  let before = 0;
  groups.forEach((group, i) => {
    if (group.collapsed) {
      const inside = before === offset || (before > offset && before < end);
      if (inside || (before === end && end >= total && records.length > 0)) {
        keep.add(i);
      }
      if (isLeaf(i)) return;
    }
    if (!isLeaf(i)) return;
    const loaded = onPage.get(group.key) ?? 0;
    if (loaded > 0) {
      keep.add(i);
      const result: SheetGroup = { ...group, loaded };
      if (before < offset) result.continued = true;
      patched.set(i, result);
    }
    before += Math.max(0, group.count);
  });
  // ancestors of what is kept
  for (const i of [...keep]) {
    let depth = groups[i]!.depth;
    for (let p = i - 1; p >= 0 && depth > 0; p--) {
      if (groups[p]!.depth < depth) {
        depth = groups[p]!.depth;
        keep.add(p);
      }
    }
  }
  return groups.flatMap((group, i) =>
    keep.has(i) ? [patched.get(i) ?? group] : []
  );
}
