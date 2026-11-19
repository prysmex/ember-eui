/**
 * The row model (V03-DESIGN.md 4.2, 7.2): which grid row is a record, an
 * add row or a group header. Grid rows are what the component's positions,
 * focus and the DOM use; record rows (indexes into `@records`) are what
 * the rest of the core uses. Without groups the model is the identity of
 * v0.2: records `0 … n-1`, then the add row at `n` when inserting is
 * allowed.
 */
import type { Range } from './types.ts';

export type SheetRow =
  /** `record` indexes `@records`. */
  | { kind: 'record'; record: number }
  /** `group` -1: the add row at the end (no groups). */
  | { kind: 'add'; group: number }
  /** `group` indexes `@groups`. */
  | { kind: 'group'; group: number };

/** What the row model reads of a group header (a `SheetGroup` from batch 3b fits). */
export interface RowModelGroup {
  /** 0 for the outermost level. */
  depth: number;
  /** How many of `@records`, taken in order, are directly under this header. Default 0. */
  loaded?: number;
  collapsed?: boolean;
}

export interface RowModel {
  readonly length: number;
  at(gridRow: number): SheetRow | undefined;
  /** -1 for a header, an add row or a row outside the model. */
  recordRowAt(gridRow: number): number;
  /** -1 for a record row outside `@records`. */
  gridRowOf(recordRow: number): number;
  /** The records inside a grid range, as a record range; null when it holds none. */
  recordRange(range: Range): Range | null;
  /** The grid rows of the first and last record; -1 without records. */
  readonly firstRecordRow: number;
  readonly lastRecordRow: number;
  /** The nearest record row at or after (step 1) / at or before (step -1) a grid row; -1 when none. */
  nearestRecordRow(gridRow: number, step: 1 | -1): number;
  /** The group a grid row is in (its header's index in @groups), -1 without groups. */
  groupAt(gridRow: number): number;
  /** The add row of a group (or of the sheet with -1); -1 when it has none. */
  addRowOf(group: number): number;
  /** The header row of a group; -1 outside `@groups` (and always without groups). */
  headerRowOf(group: number): number;
}

export function buildRowModel(input: {
  recordCount: number;
  addRow: boolean;
  /** Batch 3b. Absent or empty: the identity model. */
  groups?: readonly RowModelGroup[];
}): RowModel {
  const count = Math.max(0, Math.floor(input.recordCount));
  const groups = input.groups;
  if (!groups || !groups.length) return identityModel(count, input.addRow);
  return groupedModel(count, input.addRow, groups);
}

/* Identity: closed-form, no arrays */

function identityModel(count: number, addRow: boolean): RowModel {
  const length = count + (addRow ? 1 : 0);
  const recordRowAt = (row: number): number =>
    row >= 0 && row < count ? row : -1;
  return {
    length,
    firstRecordRow: count ? 0 : -1,
    lastRecordRow: count - 1,
    at(row) {
      if (row >= 0 && row < count) return { kind: 'record', record: row };
      if (addRow && row === count) return { kind: 'add', group: -1 };
      return undefined;
    },
    recordRowAt,
    gridRowOf: recordRowAt,
    recordRange(range) {
      const top = Math.max(range.top, 0);
      const bottom = Math.min(range.bottom, count - 1);
      if (top > bottom) return null;
      return { top, left: range.left, bottom, right: range.right };
    },
    nearestRecordRow(row, step) {
      if (!count) return -1;
      if (step === 1) return row >= count ? -1 : Math.max(row, 0);
      return row < 0 ? -1 : Math.min(row, count - 1);
    },
    groupAt: () => -1,
    addRowOf: (group) => (group === -1 && addRow ? count : -1),
    headerRowOf: () => -1
  };
}

/* Grouped: one pass over the groups, two typed arrays */

function groupedModel(
  count: number,
  addRow: boolean,
  groups: readonly RowModelGroup[]
): RowModel {
  // records per header: the next `loaded`, clamped to what is left (8.2)
  const takes = new Int32Array(groups.length);
  let left = count;
  groups.forEach((group, i) => {
    const take = Math.min(Math.max(Math.floor(group.loaded ?? 0), 0), left);
    takes[i] = take;
    left -= take;
  });
  // the rest follow the last group's records, in that group
  takes[groups.length - 1]! += left;

  // a leaf: the next group is not deeper; an add row when expanded
  const hasAdd = groups.map(
    (group, i) =>
      addRow &&
      !group.collapsed &&
      !((groups[i + 1]?.depth ?? -Infinity) > group.depth)
  );
  const length = groups.length + count + hasAdd.filter((has) => has).length;

  const rowToRecord = new Int32Array(length).fill(-1);
  const recordToRow = new Int32Array(count);
  const addRows = new Int32Array(groups.length).fill(-1);
  const headerRows = new Int32Array(groups.length);
  /** The non-record rows, ascending, with their group: for `at` and `groupAt`. */
  const otherRows: number[] = [];
  const otherGroups: number[] = [];
  const otherKinds: ('add' | 'group')[] = [];

  let row = 0;
  let record = 0;
  groups.forEach((_, i) => {
    headerRows[i] = row;
    otherRows.push(row);
    otherGroups.push(i);
    otherKinds.push('group');
    row++;
    for (let k = 0; k < takes[i]!; k++) {
      rowToRecord[row] = record;
      recordToRow[record] = row;
      row++;
      record++;
    }
    if (hasAdd[i]) {
      addRows[i] = row;
      otherRows.push(row);
      otherGroups.push(i);
      otherKinds.push('add');
      row++;
    }
  });

  const recordRowAt = (gridRow: number): number =>
    gridRow >= 0 && gridRow < length ? rowToRecord[gridRow]! : -1;

  /** The index in `otherRows` of the last entry at or before a row; -1 when none. */
  const lastOtherAtOrBefore = (gridRow: number): number => {
    let lo = 0;
    let hi = otherRows.length - 1;
    let found = -1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      if (otherRows[mid]! <= gridRow) {
        found = mid;
        lo = mid + 1;
      } else hi = mid - 1;
    }
    return found;
  };

  /** The first record whose row is at or after a grid row; `count` when none. */
  const firstRecordFrom = (gridRow: number): number => {
    let lo = 0;
    let hi = count;
    while (lo < hi) {
      const mid = (lo + hi) >> 1;
      if (recordToRow[mid]! < gridRow) lo = mid + 1;
      else hi = mid;
    }
    return lo;
  };

  /** The last record whose row is at or before a grid row; -1 when none. */
  const lastRecordUpTo = (gridRow: number): number =>
    firstRecordFrom(gridRow + 1) - 1;

  return {
    length,
    firstRecordRow: count ? recordToRow[0]! : -1,
    lastRecordRow: count ? recordToRow[count - 1]! : -1,
    at(gridRow) {
      if (gridRow < 0 || gridRow >= length) return undefined;
      const r = rowToRecord[gridRow]!;
      if (r >= 0) return { kind: 'record', record: r };
      const k = lastOtherAtOrBefore(gridRow);
      return { kind: otherKinds[k]!, group: otherGroups[k]! };
    },
    recordRowAt,
    gridRowOf: (r) => (r >= 0 && r < count ? recordToRow[r]! : -1),
    recordRange(range) {
      const top = firstRecordFrom(range.top);
      const bottom = lastRecordUpTo(range.bottom);
      if (top > bottom) return null;
      return { top, left: range.left, bottom, right: range.right };
    },
    nearestRecordRow(gridRow, step) {
      if (step === 1) {
        const r = firstRecordFrom(gridRow);
        return r < count ? recordToRow[r]! : -1;
      }
      const r = lastRecordUpTo(gridRow);
      return r >= 0 ? recordToRow[r]! : -1;
    },
    groupAt(gridRow) {
      if (gridRow < 0 || gridRow >= length) return -1;
      const k = lastOtherAtOrBefore(gridRow);
      return k >= 0 ? otherGroups[k]! : -1;
    },
    addRowOf: (group) =>
      group >= 0 && group < groups.length ? addRows[group]! : -1,
    headerRowOf: (group) =>
      group >= 0 && group < groups.length ? headerRows[group]! : -1
  };
}
