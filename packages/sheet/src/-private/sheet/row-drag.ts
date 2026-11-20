/**
 * Drag to reorder rows (V03 10.1, W6): the grip in the row-number cell,
 * the insertion line, Alt+Shift+ArrowUp/Down and `SheetApi.moveRecords`.
 * Every move is a change set with `moves` (D5); the sheet moves nothing
 * itself, it shows `@records` in the order given.
 */
import { tracked } from '@glimmer/tracking';

import { isReadOnly, moveRecords } from '../../core/index.ts';
import AutoScroll from '../auto-scroll.ts';
import { afterRender, stop } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type {
  ChangeSet,
  MoveRecordsOptions,
  RecordId,
  RecordMove
} from '../../core/index.ts';

/** A press on the grip becomes a drag past this many px. */
const DRAG_THRESHOLD = 4;

/** Where a drop would put the rows. */
interface DropTarget {
  anchor: RecordMove['anchor'] | undefined;
  options: MoveRecordsOptions;
  /** A group field is read-only for a moved record (10.1): no drop. */
  blocked: boolean;
}

/** The insertion line, in the wrapper's CSS px; `height` set: a box around a collapsed header. */
export interface DropLine {
  top: number;
  left: number;
  width: number;
  height?: number;
  blocked: boolean;
}

export default class SheetRowDrag<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The ids of the rows being dragged (drawn dimmed), as strings. */
  @tracked moving: ReadonlySet<string> | null = null;
  /** The insertion line while a drag is over a target. */
  @tracked line: DropLine | null = null;

  /** A press on the grip, until it ends. */
  press: { ids: RecordId[]; row: number; x: number; y: number } | null = null;
  /** The target under the pointer. */
  target: DropTarget | null = null;
  /** The drag's auto-scroll loop (the range drag's, 8.4). */
  autoScroll = new AutoScroll({
    bounds: () => this.sheet.scroll.scrollBounds(),
    scrollBy: (dx, dy) => this.sheet.scroll.scrollGridBy(dx, dy),
    onFrame: (x, y) => this.over(x, y)
  });
  /** The moved records to select once the owner's `@records` has them. */
  pendingSelect: {
    ids: string[];
    focus: string;
    records: readonly T[];
  } | null = null;

  /**
   * Moves are allowed (10.1): `@canMove`, not `@readOnly`, and no `@sort`
   * (with a sort the order is the sort's).
   */
  get enabled(): boolean {
    const args = this.sheet.args;
    return !!args.canMove && !args.readOnly && !args.sort?.length;
  }

  /** The row-number cells draw the grip: moves are allowed and there are row numbers. */
  get showsGrip(): boolean {
    return this.enabled && this.sheet.showRowNumbers;
  }

  /** A drag is past its threshold. */
  get active(): boolean {
    return this.moving !== null;
  }

  isMoving(row: number): boolean {
    const moving = this.moving;
    if (!moving) return false;
    const record = this.sheet.rows.recordAt(row);
    return (
      record !== undefined &&
      moving.has(String(this.sheet.args.getRecordId(record)))
    );
  }

  /**
   * The records a press on `row` moves: the checked records when the row
   * is checked, the rows of a `'rows'` range that holds it, else the row.
   */
  idsFor(row: number): RecordId[] {
    const record = this.sheet.rows.recordAt(row);
    if (record === undefined) return [];
    const getId = this.sheet.args.getRecordId;
    if (this.sheet.checked.isChecked(row)) {
      return this.sheet.checked.checkedRecords.map(getId);
    }
    const selection = this.sheet.selection;
    if (selection.rangeKind === 'rows' && selection.isRowSelected(row)) {
      const range =
        selection.range && this.sheet.rows.recordRange(selection.range);
      if (range) {
        return this.sheet.args.records
          .slice(range.top, range.bottom + 1)
          .map(getId);
      }
    }
    return [getId(record)];
  }

  /* -------------------------------------------------------------------- */
  /* The pointer                                                           */
  /* -------------------------------------------------------------------- */

  /** A left press on a row's grip (from the sheet's capture `mousedown`). */
  start(event: MouseEvent, row: number): void {
    const ids = this.idsFor(row);
    if (!ids.length) return;
    // no text selection, no focus change: the drag is the gesture
    event.preventDefault();
    this.press = { ids, row, x: event.clientX, y: event.clientY };
    document.addEventListener('mousemove', this.onMove, true);
    document.addEventListener('mouseup', this.onRelease, true);
    document.addEventListener('keydown', this.onKeyDown, true);
  }

  onMove = (event: MouseEvent): void => {
    const press = this.press;
    if (!press) return;
    if (!this.moving) {
      const distance = Math.hypot(
        event.clientX - press.x,
        event.clientY - press.y
      );
      if (distance < DRAG_THRESHOLD) return;
      this.moving = new Set(press.ids.map(String));
    }
    window.getSelection()?.removeAllRanges();
    this.over(event.clientX, event.clientY);
    this.autoScroll.update(event.clientX, event.clientY);
  };

  onRelease = (): void => {
    const dragged = this.moving !== null;
    const press = this.press;
    const target = this.target;
    this.end();
    if (!press) return;
    if (!dragged) {
      // a click on the grip: as on the row number, the row is selected
      this.sheet.selection.selectRows(press.row, false);
      this.sheet.focus.keepRangeOnFocus = true;
      this.sheet.focus.rowCursor = press.row;
      this.sheet.dom.focusRowNumberCell(press.row);
      return;
    }
    // the click that follows is the end of the drag
    this.sheet.drag.suppressClick = true;
    if (!target || target.blocked) return;
    this.emitMove(
      moveRecords(this.sheet.context, press.ids, target.anchor, {
        ...target.options,
        equals: (fieldId, a, b) => this.sheet.fields.valueEquals(fieldId, a, b)
      }),
      press.ids,
      press.ids[0]!
    );
  };

  /** Escape cancels a drag (RD5). */
  onKeyDown = (event: KeyboardEvent): void => {
    if (event.key !== 'Escape' || !this.press) return;
    stop(event);
    this.end();
  };

  /** Ends a press or a drag without a move. */
  end(): void {
    document.removeEventListener('mousemove', this.onMove, true);
    document.removeEventListener('mouseup', this.onRelease, true);
    document.removeEventListener('keydown', this.onKeyDown, true);
    this.autoScroll.stop();
    this.press = null;
    this.target = null;
    if (this.moving) this.moving = null;
    if (this.line) this.line = null;
  }

  /**
   * The pointer is at `x`, `y` (a move, or an auto-scroll frame): the row
   * under it and its upper or lower half give the target and the line.
   * Off the rows the last target stays.
   */
  over(x: number, y: number): void {
    if (!this.press || !this.moving) return;
    const element = document.elementFromPoint(x, y);
    const cell =
      this.sheet.dom.rowNumberCell(element) ?? this.sheet.dom.dataCell(element);
    if (!cell) return;
    const row = this.sheet.dom.rowIndexOf(cell);
    const box = cell.getBoundingClientRect();
    const upper = y < box.top + box.height / 2;
    const found = this.targetAt(row, upper, this.press.ids);
    if (!found) return;
    this.target = found.target;
    this.line = this.lineAt(box, found.edge, found.target.blocked);
  }

  /** The line along the top or bottom edge of a row's box, as wide as the grid; `box`: around it. */
  lineAt(
    box: DOMRect,
    edge: 'top' | 'bottom' | 'box',
    blocked: boolean
  ): DropLine {
    const dom = this.sheet.dom;
    const grid = this.sheet.wrapper?.querySelector('.euiSheet__grid');
    const outer = (grid ?? this.sheet.wrapper)?.getBoundingClientRect();
    const left = dom.pointInWrapper(outer?.left ?? box.left, box.top);
    const right = dom.pointInWrapper(outer?.right ?? box.right, box.bottom);
    let top = edge === 'bottom' ? right.top : left.top;
    // a row cut by the body's edge: the line stays in the body
    const bounds = this.sheet.scroll.scrollBounds();
    if (bounds && edge !== 'box') {
      const min = dom.pointInWrapper(bounds.left, bounds.top).top;
      const max = dom.pointInWrapper(bounds.left, bounds.bottom).top;
      top = Math.min(Math.max(top, min), max);
    }
    const line: DropLine = {
      top,
      left: left.left,
      width: right.left - left.left,
      blocked
    };
    if (edge === 'box') line.height = right.top - left.top;
    return line;
  }

  /* -------------------------------------------------------------------- */
  /* Targets (10.1)                                                        */
  /* -------------------------------------------------------------------- */

  /**
   * The target of a drop on grid row `row` (its upper half with `upper`):
   * between two records, after the upper one; grouped, on a header into
   * its group at the start (a collapsed one with no anchor), on an add row
   * at its group's end.
   */
  targetAt(
    row: number,
    upper: boolean,
    ids: readonly RecordId[]
  ): { target: DropTarget; edge: 'top' | 'bottom' | 'box' } | null {
    const rows = this.sheet.rows;
    const kind = rows.rowKind(row);
    if (kind === undefined) return null;
    const records = this.sheet.args.records;
    const getId = this.sheet.args.getRecordId;
    if (!rows.isGrouped) {
      if (kind === 'add') {
        return { target: this.build(undefined, undefined, ids), edge: 'top' };
      }
      const record = rows.recordAt(row);
      if (record === undefined) return null;
      return {
        target: this.build(
          { recordId: getId(record), position: upper ? 'before' : 'after' },
          undefined,
          ids
        ),
        edge: upper ? 'top' : 'bottom'
      };
    }
    const model = rows.rowModel;
    if (kind === 'record') {
      const record = rows.recordAt(row)!;
      return {
        target: this.build(
          { recordId: getId(record), position: upper ? 'before' : 'after' },
          model.groupAt(row),
          ids
        ),
        edge: upper ? 'top' : 'bottom'
      };
    }
    if (kind === 'add') {
      return {
        target: this.build(undefined, model.groupAt(row), ids),
        edge: 'top'
      };
    }
    // a header: into its first leaf group, at its start
    const leaf = this.leafOf(row);
    const group = rows.groups[leaf];
    if (!group) return null;
    if (group.collapsed) {
      return { target: this.build(undefined, leaf, ids), edge: 'box' };
    }
    const range = this.groupRange(leaf);
    const first = records[range.start];
    const anchor =
      range.end > range.start && first !== undefined
        ? { recordId: getId(first), position: 'before' as const }
        : undefined;
    return {
      target: this.build(anchor, leaf, ids),
      edge: model.headerRowOf(leaf) === row ? 'bottom' : 'top'
    };
  }

  /** The leaf group a header row leads to: itself, or (expanded, with child headers) its first descendant leaf. */
  leafOf(headerRow: number): number {
    const model = this.sheet.rows.rowModel;
    const groups = this.sheet.rows.groups;
    let row = headerRow;
    for (;;) {
      const at = model.at(row);
      const next = model.at(row + 1);
      if (at?.kind !== 'group' || next?.kind !== 'group') break;
      const group = groups[at.group]!;
      if (group.collapsed || groups[next.group]!.depth <= group.depth) break;
      row++;
    }
    const at = model.at(row);
    return at?.kind === 'group' ? at.group : -1;
  }

  /** The record indexes of a group's loaded records: `[start, end)`. */
  groupRange(group: number): { start: number; end: number } {
    const rows = this.sheet.rows;
    const header = rows.rowModel.headerRowOf(group);
    const start = rows.coreRowOf(header);
    let end = start;
    for (let row = header + 1; rows.rowKind(row) === 'record'; row++) end++;
    return { start, end };
  }

  /** The leaf group's key of the record at a record index (grouped). */
  groupKeyOf = (index: number): string | undefined => {
    const model = this.sheet.rows.rowModel;
    return this.sheet.rows.groups[model.groupAt(model.gridRowOf(index))]?.key;
  };

  /** A target's options, and whether a group field blocks it. */
  build(
    anchor: RecordMove['anchor'] | undefined,
    group: number | undefined,
    ids: readonly RecordId[]
  ): DropTarget {
    const options: MoveRecordsOptions = {};
    if (group === undefined || group < 0 || !this.sheet.rows.isGrouped) {
      return { anchor, options, blocked: false };
    }
    const key = this.sheet.rows.groups[group]!.key;
    const values = this.sheet.groupHeaders.groupValuesOf(group);
    options.group = { key, values, ...this.groupRange(group) };
    options.groupKeyOf = this.groupKeyOf;
    return { anchor, options, blocked: this.blocks(key, values, ids) };
  }

  /** A moved record from another group whose group field is read-only for it (RD9). */
  blocks(
    key: string,
    values: Record<string, unknown>,
    ids: readonly RecordId[]
  ): boolean {
    const fields = this.sheet.fields.allFields.filter(
      (field) => field.id in values
    );
    if (!fields.length) return false;
    const wanted = new Set(ids.map(String));
    const records = this.sheet.args.records;
    return records.some(
      (record, index) =>
        wanted.has(String(this.sheet.args.getRecordId(record))) &&
        this.groupKeyOf(index) !== key &&
        fields.some((field) => isReadOnly(this.sheet.context, field, record))
    );
  }

  /* -------------------------------------------------------------------- */
  /* Keys and the API                                                      */
  /* -------------------------------------------------------------------- */

  /**
   * Alt+Shift+ArrowUp / ArrowDown (10.1): the rows of `row` (as a press on
   * its grip takes them) one record up or down, one change set per press.
   * Grouped, a step past a group's edge lands at the next group's start or
   * the previous group's end. Nothing at the first or last record.
   */
  moveByKey(row: number, step: 1 | -1): void {
    if (!this.enabled) return;
    const ids = this.idsFor(row);
    if (!ids.length) return;
    const records = this.sheet.args.records;
    const getId = this.sheet.args.getRecordId;
    const wanted = new Set(ids.map(String));
    const indexes: number[] = [];
    records.forEach((record, index) => {
      if (wanted.has(String(getId(record)))) indexes.push(index);
    });
    if (!indexes.length) return;
    const edge = step === 1 ? indexes[indexes.length - 1]! : indexes[0]!;
    let next = edge + step;
    while (
      next >= 0 &&
      next < records.length &&
      wanted.has(String(getId(records[next]!)))
    )
      next += step;
    if (next < 0 || next >= records.length) return;
    const neighbour = getId(records[next]!);
    const rows = this.sheet.rows;
    let anchor: RecordMove['anchor'] = {
      recordId: neighbour,
      position: step === 1 ? 'after' : 'before'
    };
    let group: number | undefined;
    if (rows.isGrouped) {
      const model = rows.rowModel;
      group = model.groupAt(model.gridRowOf(next));
      // the neighbour is in another group: the rows go to that group's edge
      if (group !== model.groupAt(model.gridRowOf(edge))) {
        anchor = {
          recordId: neighbour,
          position: step === 1 ? 'before' : 'after'
        };
      }
    }
    const target = this.build(anchor, group, ids);
    if (target.blocked) return;
    const focus = this.sheet.rows.recordAt(row);
    this.emitMove(
      moveRecords(this.sheet.context, ids, target.anchor, {
        ...target.options,
        equals: (fieldId, a, b) => this.sheet.fields.valueEquals(fieldId, a, b)
      }),
      ids,
      focus === undefined ? ids[0]! : getId(focus)
    );
  }

  /** `SheetApi.moveRecords(ids, target)`: the set a drop next to `target` emits. */
  moveFromApi(
    ids: RecordId[],
    target: { recordId: RecordId; position: 'before' | 'after' }
  ): void {
    if (!this.enabled) return;
    const rows = this.sheet.rows;
    const at = rows.rowOf(target.recordId, 0);
    if (at < 0) return;
    const group = rows.isGrouped
      ? rows.rowModel.groupAt(rows.gridRowOf(at))
      : undefined;
    const built = this.build(target, group, ids);
    if (built.blocked) return;
    this.sheet.changes.emit(
      moveRecords(this.sheet.context, ids, built.anchor, {
        ...built.options,
        equals: (fieldId, a, b) => this.sheet.fields.valueEquals(fieldId, a, b)
      }),
      []
    );
  }

  /* -------------------------------------------------------------------- */
  /* After a move                                                          */
  /* -------------------------------------------------------------------- */

  /** Emits a move and selects its rows once the owner has applied it. */
  emitMove(
    changeSet: ChangeSet | null,
    ids: RecordId[],
    focus: RecordId
  ): void {
    if (!changeSet) return;
    const records = this.sheet.args.records;
    this.sheet.changes.emit(changeSet, []);
    this.selectAfter(ids, focus, records);
  }

  /**
   * After an emitted move (or its undo or redo): once `@records` is a new
   * array, the moved rows are selected and the row number of `focus` gets
   * focus. An owner that ignored the move: nothing.
   */
  selectAfter(ids: RecordId[], focus: RecordId, records: readonly T[]): void {
    this.pendingSelect = {
      ids: ids.map(String),
      focus: String(focus),
      records
    };
    afterRender(this.sheet, () => {
      // the owner did not apply it in this run loop
      if (this.pendingSelect?.records === this.sheet.args.records) {
        this.pendingSelect = null;
      }
    });
  }

  /** From the records watcher, after the sheet followed a new `@records`. */
  applyPendingSelect(): void {
    const pending = this.pendingSelect;
    if (!pending || pending.records === this.sheet.args.records) return;
    this.pendingSelect = null;
    const rows = this.sheet.rows;
    const getId = this.sheet.args.getRecordId;
    const wanted = new Set(pending.ids);
    const gridRows: number[] = [];
    let focusRow = -1;
    this.sheet.args.records.forEach((record, index) => {
      const id = String(getId(record));
      if (!wanted.has(id)) return;
      const row = rows.gridRowOf(index);
      gridRows.push(row);
      if (id === pending.focus) focusRow = row;
    });
    if (!gridRows.length) return;
    if (focusRow < 0) focusRow = gridRows[0]!;
    const top = Math.min(...gridRows);
    const bottom = Math.max(...gridRows);
    const selection = this.sheet.selection;
    // one block of rows: select it; else only the focused row
    const contiguous = gridRows.length === bottom - top + 1;
    const from = contiguous ? top : focusRow;
    const to = contiguous ? bottom : focusRow;
    selection.anchor = { row: from, col: 0 };
    selection.head = {
      row: to,
      col: Math.max(this.sheet.fields.visibleFields.length - 1, 0)
    };
    selection.rangeKind = 'rows';
    if (!this.sheet.colOffset) return;
    this.sheet.focus.keepRangeOnFocus = true;
    this.sheet.focus.rowCursor = focusRow;
    this.sheet.dom.focusRowNumberCell(focusRow);
  }
}
