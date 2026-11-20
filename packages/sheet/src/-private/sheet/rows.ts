/** The row model: records, group headers and add rows by grid row, and the row numbers (V03C-DESIGN.md 3.2). */
import { cached } from '@glimmer/tracking';
import { warn } from '@ember/debug';

import { buildRowModel, edgeTarget } from '../../core/index.ts';
import { clamp } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type {
  Pos,
  Range,
  RecordId,
  RowModel,
  SheetGroup,
  SheetRow
} from '../../core/index.ts';

export default class SheetRows<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Whether the grid has an "add" row after the records. */
  get hasAddRow(): boolean {
    return this.sheet.canInsert;
  }

  /** The sheet's add row, or (grouped) any group's add row (V03 8.4). */
  isAddRow(row: number): boolean {
    if (row < 0) return false;
    if (this.isGrouped) return this.rowModel.at(row)?.kind === 'add';
    return row === this.rowModel.addRowOf(-1);
  }

  /** The group whose add row this is (its index in `@groups`); -1 for any other row. */
  addRowGroupAt(row: number): number {
    if (!this.isGrouped) return -1;
    const at = this.rowModel.at(row);
    return at?.kind === 'add' ? at.group : -1;
  }

  get rowNumberOffset(): number {
    return this.sheet.args.rowNumberOffset ?? 0;
  }

  /**
   * The number a record row shows: `@rowNumberOffset + recordRow + 1`; with
   * groups that set `rowNumberStart`, the numbers of `rowNumbers` (V03 8.4).
   */
  numberOf(recordRow: number): number {
    const numbers = this.rowNumbers;
    if (numbers && recordRow >= 0 && recordRow < numbers.length) {
      return numbers[recordRow]!;
    }
    return this.rowNumberOffset + recordRow + 1;
  }

  /**
   * Each record's number while some group has `rowNumberStart` (V03 8.4),
   * else null: one more than the previous record's, from
   * `@rowNumberOffset + 1`; a group's first record takes its
   * `rowNumberStart`, or the nearest ancestor's when it has none.
   */
  @cached
  get rowNumbers(): Int32Array | null {
    const groups = this.groups;
    if (!groups.some((group) => group.rowNumberStart !== undefined)) {
      return null;
    }
    const model = this.rowModel;
    const count = this.sheet.args.records.length;
    const numbers = new Int32Array(count);
    let previous = this.rowNumberOffset;
    // the groups up to the last numbered record's: their starts are used
    let done = -1;
    for (let r = 0; r < count; r++) {
      const group = model.groupAt(model.gridRowOf(r));
      let start: number | undefined;
      if (group > done) {
        // the group itself, then its ancestors among the groups since then
        let depth = Infinity;
        for (let i = group; i > done && start === undefined; i--) {
          const candidate = groups[i]!;
          if (candidate.depth >= depth) continue;
          depth = candidate.depth;
          start = candidate.rowNumberStart;
        }
        done = group;
      }
      previous = start ?? previous + 1;
      numbers[r] = previous;
    }
    return numbers;
  }

  /** The position a grid row shows: its record's number. */
  positionOf(row: number): number {
    return this.numberOf(this.recordRowAt(row));
  }

  /** What a row-number cell shows: `@rowLabel`, else the position. */
  rowLabelOf(row: number): string {
    const record = this.recordAt(row);
    if (record === undefined) return '';
    const position = this.positionOf(row);
    return this.sheet.args.rowLabel
      ? this.sheet.args.rowLabel(record, position)
      : String(position);
  }

  /* Rows (V03-DESIGN.md 4.2, 7.3): grid rows are positions, focus and the
     DOM; record rows index `@records` and are what the core gets */

  /** `@groups`, or none. */
  get groups(): readonly SheetGroup[] {
    return this.sheet.args.groups ?? [];
  }

  get isGrouped(): boolean {
    return this.groups.length > 0;
  }

  /** Which grid row is a record, an add row or a group header. */
  @cached
  get rowModel(): RowModel {
    const count = this.sheet.args.records.length;
    const groups = this.sheet.args.groups;
    if (groups?.length) {
      // the records past Σ loaded are drawn in the last group (V03 8.2)
      const loaded = groups.reduce(
        (sum, group) => sum + Math.max(0, Math.floor(group.loaded ?? 0)),
        0
      );
      warn(
        `EuiSheet: the groups' \`loaded\` add up to ${loaded}, but @records has ${count} records: the last ${count - loaded} are drawn in the last group.`,
        loaded >= count,
        { id: 'ember-eui.sheet.groups-loaded-mismatch' }
      );
    }
    return buildRowModel({
      recordCount: count,
      addRow: this.hasAddRow,
      groups
    });
  }

  get rowCount(): number {
    return this.rowModel.length;
  }

  /** The record of a grid row; `undefined` for the add row. */
  recordAt(row: number): T | undefined {
    const r = this.rowModel.recordRowAt(row);
    return r < 0 ? undefined : this.sheet.args.records[r];
  }

  /** The record row of a grid row; -1 for a row that is not a record. */
  recordRowAt(row: number): number {
    return this.rowModel.recordRowAt(row);
  }

  /** The grid row of a record row; -1 outside `@records`. */
  gridRowOf(recordRow: number): number {
    return this.rowModel.gridRowOf(recordRow);
  }

  /** The records inside a grid range, as a record range; null when it holds none. */
  recordRange(range: Range): Range | null {
    return this.rowModel.recordRange(range);
  }

  /** A grid position as a record position; `row` -1 when it is not on a record. */
  recordPos(pos: Pos): Pos {
    return { row: this.recordRowAt(pos.row), col: pos.col };
  }

  /**
   * A grid row as the core sees it: its record row; for an add row (or a
   * header), the record row after the records above it, as v0.2 passed
   * `records.length` for the add row.
   */
  coreRowOf(row: number): number {
    const r = this.recordRowAt(row);
    if (r >= 0) return r;
    const above = this.rowModel.nearestRecordRow(row, -1);
    return above < 0 ? 0 : this.recordRowAt(above) + 1;
  }

  /** A record position (from the core) as a grid position. */
  gridPos(pos: Pos): Pos {
    return { row: this.gridRowOf(pos.row), col: pos.col };
  }

  rowKind(row: number): SheetRow['kind'] | undefined {
    return this.rowModel.at(row)?.kind;
  }

  isRecordRow(row: number): boolean {
    return this.recordRowAt(row) >= 0;
  }

  /** The record row nearest a grid row, looking up first (the v0.2 clamp to the last record); `fallback` without records. */
  clampToRecordRow(row: number, fallback: number): number {
    const model = this.rowModel;
    const up = model.nearestRecordRow(row, -1);
    if (up >= 0) return up;
    const down = model.nearestRecordRow(row, 1);
    return down >= 0 ? down : fallback;
  }

  /**
   * Grouped: the row nearest `row` (clamped to the grid) a key may land
   * on, looking in `step`'s direction first, then the other way: not a
   * header (a record or an add row), or with `recordsOnly` a record. -1
   * when there is none (V03 8.6, stage 3.2a).
   */
  landingRow(row: number, step: 1 | -1, recordsOnly: boolean): number {
    const model = this.rowModel;
    if (!model.length) return -1;
    const from = clamp(row, 0, model.length - 1);
    if (recordsOnly) {
      const ahead = model.nearestRecordRow(from, step);
      return ahead >= 0
        ? ahead
        : model.nearestRecordRow(from, step === 1 ? -1 : 1);
    }
    const lands = (g: number) => model.at(g)?.kind !== 'group';
    if (lands(from)) return from;
    for (let g = from + step; g >= 0 && g < model.length; g += step) {
      if (lands(g)) return g;
    }
    for (let g = from - step; g >= 0 && g < model.length; g -= step) {
      if (lands(g)) return g;
    }
    return -1;
  }

  /** Where Ctrl+Home lands: the first record, else (grouped, none) the first add row; -1 for none. */
  firstLandingRow(): number {
    const first = this.rowModel.firstRecordRow;
    if (first >= 0 || !this.isGrouped) return Math.max(first, 0);
    return this.landingRow(0, 1, false);
  }

  /** Where Ctrl+End lands: the grid's last row, which grouped is the last row that is not a header. */
  lastLandingRow(): number {
    const last = this.rowCount - 1;
    return this.isGrouped ? this.landingRow(last, -1, false) : last;
  }

  /**
   * The run of record rows a record row is in, in grid rows: its group's
   * records (between its header and its add row or the next header), or
   * every record without groups. The range outline draws one box per run
   * (V03 8.5: the drawn selection is the records).
   */
  recordRunOf(row: number): { top: number; bottom: number } {
    const model = this.rowModel;
    if (!this.isGrouped) {
      return { top: model.firstRecordRow, bottom: model.lastRecordRow };
    }
    const group = model.groupAt(row);
    const add = model.addRowOf(group);
    const next = model.headerRowOf(group + 1);
    return {
      top: model.headerRowOf(group) + 1,
      bottom: (add >= 0 ? add : next >= 0 ? next : model.length) - 1
    };
  }

  /**
   * Ctrl/Cmd+arrow on a header or an add row while grouped (V03 8.5): the
   * row is an empty cell between the records above and below it, as the
   * add row at the end was in v0.2 (`edgeTarget` from past the records).
   * Left and right do not move there, as on v0.2's add row.
   */
  edgeFromGap(from: Pos, direction: 'up' | 'down' | 'left' | 'right'): Pos {
    if (direction !== 'up' && direction !== 'down') return from;
    const ctx = this.sheet.context;
    // the records above the row
    const above = this.coreRowOf(from.row);
    if (direction === 'up') {
      const edge = edgeTarget(
        { ...ctx, records: ctx.records.slice(0, above) },
        { row: above, col: from.col },
        'up'
      );
      return edge.row === above ? from : this.gridPos(edge);
    }
    const edge = edgeTarget(
      { ...ctx, records: ctx.records.slice(above) },
      { row: -1, col: from.col },
      'down'
    );
    return edge.row < 0
      ? from
      : { row: this.gridRowOf(edge.row + above), col: edge.col };
  }

  /**
   * The record row of a record now, trying `hint` (a record row) first; -1
   * when it is gone. Callers that focus or select convert with `gridRowOf`.
   */
  rowOf(recordId: RecordId, hint: number): number {
    const records = this.sheet.args.records;
    const getId = this.sheet.args.getRecordId;
    const id = String(recordId);
    const atHint = records[hint];
    if (atHint !== undefined && String(getId(atHint)) === id) return hint;
    return records.findIndex((record) => String(getId(record)) === id);
  }

  /** A `rowOf` hint from a grid row: its record row, else 0. */
  hintOf(gridRow: number | undefined): number {
    return Math.max(this.recordRowAt(gridRow ?? 0), 0);
  }
}
