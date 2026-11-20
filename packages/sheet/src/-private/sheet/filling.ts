/** The fill handle, Ctrl+D and Ctrl+R (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { isDestroying } from '@ember/destroyable';

import { fillDown, fillRange, fillRight } from '../../core/index.ts';
import { samePos, sameRange, stop } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos, Range } from '../../core/index.ts';

/** The fill handle's drawn size in px: a 10 px square and its 2 px ring (`styles.ts`). */
const FILL_HANDLE_SIZE = 14;

export default class SheetFilling<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /* Batch 6: fill handle, auto-scroll, touch, composition (V02-DESIGN.md 8.4-8.6) */
  /** A fill drag: the range it fills from, and the range it fills now (the preview). */
  fillSource: Range | null = null;
  @tracked fillTarget: Range | null = null;

  /* -------------------------------------------------------------------- */
  /* The fill handle (V02-DESIGN.md 8.4)                                   */
  /* -------------------------------------------------------------------- */

  /** The range the fill handle is drawn for: cells, a writable sheet, no editor. */
  get fillHandleRange(): Range | null {
    const range = this.sheet.selection.range;
    if (!range || this.sheet.args.readOnly || this.sheet.edit.editing)
      return null;
    if (this.sheet.selection.rangeKind !== 'cells') return null;
    if (!this.sheet.rows.recordRange(range)) return null;
    // the touch selection handles take its corner (V03 11.3)
    if (this.sheet.selectionHandles.range) return null;
    return range;
  }

  /** Puts the handle at the corner of the range's last cell, or hides it while that corner is not in view. */
  placeFillHandle(element: HTMLElement, range: Range): void {
    // the range's last record row
    const records = this.sheet.rows.recordRange(range);
    const corner = {
      row: records ? this.sheet.rows.gridRowOf(records.bottom) : -1,
      col: range.right
    };
    const cell = records ? this.sheet.dom.cellElement(corner) : null;
    const bounds = cell && this.sheet.scroll.scrollBounds();
    const rect = cell && this.sheet.dom.rectOf(cell);
    let shown = false;
    let box: DOMRect | undefined;
    if (cell && bounds && rect) {
      box = cell.getBoundingClientRect();
      const left =
        bounds.frozenRight !== undefined &&
        corner.col >= this.sheet.frozen.frozenCount
          ? bounds.frozenRight
          : bounds.left;
      shown =
        box.right >= left &&
        box.right <= bounds.right + 1 &&
        box.bottom >= bounds.top &&
        box.bottom <= bounds.bottom + 1;
    }
    element.style.display = shown ? '' : 'none';
    if (shown && rect && box && bounds) {
      // centred on the corner (14 px drawn: `styles.ts`), moved in so it is
      // whole at the grid body's right and bottom edges
      const half = FILL_HANDLE_SIZE / 2;
      const pastRight = Math.max(0, box.right + half - bounds.right);
      const pastBottom = Math.max(0, box.bottom + half - bounds.bottom);
      element.style.top = `${rect.top + rect.height - half - pastBottom}px`;
      element.style.left = `${rect.left + rect.width - half - pastRight}px`;
    }
  }

  /** A press on the handle starts a fill drag; focus stays on the cell. */
  onFillHandlePress = (event: MouseEvent): void => {
    event.preventDefault();
    if (event.button !== 0) return;
    const range = this.fillHandleRange;
    if (!range) return;
    this.fillSource = range;
    this.fillTarget = range;
    this.sheet.drag.dragPointer = { x: event.clientX, y: event.clientY };
    document.addEventListener('mousemove', this.onFillMove, true);
    document.addEventListener('mouseup', this.onFillRelease, true);
    document.addEventListener('keydown', this.onFillKeyDown, true);
  };

  onFillMove = (event: MouseEvent): void => {
    const source = this.fillSource;
    if (!source) return;
    this.sheet.drag.dragPointer = { x: event.clientX, y: event.clientY };
    this.sheet.drag.dragTo(event.clientX, event.clientY);
    const target = this.fillTarget;
    this.sheet.drag.feedAutoScroll(
      event.clientX,
      event.clientY,
      !!target && !sameRange(target, source)
    );
  };

  /** The fill reaches the cell at `element`: the source extended along the dominant axis. */
  fillTo(element: Element | null): void {
    const source = this.fillSource;
    const cell = this.sheet.dom.dataCell(element);
    if (!source || !cell) return;
    const pos = this.sheet.dom.cursor(cell);
    let row: number;
    let down: number;
    let up: number;
    if (this.sheet.rows.isGrouped) {
      // measured in records (V03 8.5): a header or an add row counts for
      // nothing, and stands for the record on the source's side of it
      const records = this.sheet.rows.recordRange(source);
      if (!records) return;
      row = this.sheet.rows.isRecordRow(pos.row)
        ? pos.row
        : this.sheet.rows.rowModel.nearestRecordRow(
            pos.row,
            pos.row > this.sheet.rows.gridRowOf(records.bottom) ? -1 : 1
          );
      if (row < 0) return;
      const r = this.sheet.rows.recordRowAt(row);
      down = r - records.bottom;
      up = records.top - r;
    } else {
      // a fill never reaches the add row
      row = this.sheet.rows.clampToRecordRow(pos.row, pos.row);
      down = row - source.bottom;
      up = source.top - row;
    }
    const right = pos.col - source.right;
    const left = source.left - pos.col;
    const dy = Math.max(down, up, 0);
    const dx = Math.max(right, left, 0);
    let target = source;
    if (dy > 0 && dy >= dx) {
      target = down > 0 ? { ...source, bottom: row } : { ...source, top: row };
    } else if (dx > 0) {
      target =
        right > 0
          ? { ...source, right: pos.col }
          : { ...source, left: pos.col };
    }
    const current = this.fillTarget;
    if (!current || !sameRange(current, target)) this.fillTarget = target;
  }

  /** The cells a fill writes: the target without the source. */
  fillWritten(source: Range, target: Range): Range {
    if (target.bottom > source.bottom) {
      return { ...target, top: source.bottom + 1 };
    }
    if (target.top < source.top) return { ...target, bottom: source.top - 1 };
    if (target.right > source.right) {
      return { ...target, left: source.right + 1 };
    }
    return { ...target, right: source.left - 1 };
  }

  /** The release fills (Ctrl or Alt held: copies, no series) and selects the union. */
  onFillRelease = (event: MouseEvent): void => {
    const source = this.fillSource;
    const target = this.fillTarget;
    this.stopFillDrag();
    this.sheet.frozen.pressing = false;
    // the press's scroll is not one to restore (a fill may auto-scroll)
    this.sheet.frozen.scrollLeftBeforeFocus = null;
    // the click that may follow is the end of the drag
    this.sheet.drag.suppressClick = true;
    if (!source || !target || sameRange(source, target)) return;
    const recordSource = this.sheet.rows.recordRange(source);
    const recordTarget = this.sheet.rows.recordRange(target);
    if (!recordSource || !recordTarget) return;
    this.sheet.changes.emit(
      fillRange(this.sheet.context, recordSource, recordTarget, {
        copy: event.ctrlKey || event.altKey
      }),
      this.sheet.selection.touchedIn(this.fillWritten(source, target), true)
    );
    // the union is the range; focus stays where it was when that cell is
    // one of its corners (a single cell filled down), else it moves to the
    // nearest corner
    const head = this.sheet.selection.head ?? {
      row: source.top,
      col: source.left
    };
    const corners = [
      { row: target.top, col: target.left },
      { row: target.top, col: target.right },
      { row: target.bottom, col: target.left },
      { row: target.bottom, col: target.right }
    ];
    const distance = (pos: Pos) =>
      Math.abs(pos.row - head.row) + Math.abs(pos.col - head.col);
    const next = corners.reduce((best, pos) =>
      distance(pos) < distance(best) ? pos : best
    );
    this.sheet.selection.anchor = {
      row: next.row === target.top ? target.bottom : target.top,
      col: next.col === target.left ? target.right : target.left
    };
    this.sheet.selection.head = next;
    this.sheet.selection.rangeKind = 'cells';
    // focus moves to the new corner, or back to the cell an auto-scroll
    // unmounted (focus left with it)
    const active = this.sheet.dom.dataCell(document.activeElement);
    if (!active || !samePos(this.sheet.dom.cursor(active), next)) {
      this.sheet.focus.domCursor = next;
      this.sheet.dom.focusGridCell(next);
    }
  };

  /** Escape during a fill drag cancels it. */
  onFillKeyDown = (event: KeyboardEvent): void => {
    if (event.key !== 'Escape') return;
    stop(event);
    this.stopFillDrag();
  };

  stopFillDrag(): void {
    document.removeEventListener('mousemove', this.onFillMove, true);
    document.removeEventListener('mouseup', this.onFillRelease, true);
    document.removeEventListener('keydown', this.onFillKeyDown, true);
    if (!this.fillSource) return;
    this.fillSource = null;
    this.sheet.drag.autoScroll.stop();
    this.sheet.drag.dragPointer = null;
    if (!isDestroying(this.sheet) && this.fillTarget) this.fillTarget = null;
  }

  /** Whether a cell is in the fill drag's preview (the target, not the source). */
  isFillPreview(row: number, col: number): boolean {
    const target = this.fillTarget;
    const source = this.fillSource;
    if (!target || !source) return false;
    // grouped: a header or an add row inside the target is not filled
    if (this.sheet.rows.isGrouped && !this.sheet.rows.isRecordRow(row))
      return false;
    const inside = (range: Range) =>
      row >= range.top &&
      row <= range.bottom &&
      col >= range.left &&
      col <= range.right;
    return inside(target) && !inside(source);
  }

  /** Ctrl/Cmd+R: fill the range right, or the cell from the one to its left. */
  fillRightSelection(): void {
    const range =
      this.sheet.selection.range &&
      this.sheet.rows.recordRange(this.sheet.selection.range);
    if (!range) return;
    const targets =
      range.right > range.left ? { ...range, left: range.left + 1 } : range;
    this.sheet.changes.emit(
      fillRight(this.sheet.context, range),
      this.sheet.selection.touchedInRecords(targets, true)
    );
  }

  /** Ctrl/Cmd+D: fill the range down, or the cell from the one above. */
  fill(): void {
    const range =
      this.sheet.selection.range &&
      this.sheet.rows.recordRange(this.sheet.selection.range);
    if (!range) return;
    // the cells written: below the top record, or the record itself (from above)
    const targets =
      range.bottom > range.top ? { ...range, top: range.top + 1 } : range;
    this.sheet.changes.emit(
      fillDown(this.sheet.context, range),
      this.sheet.selection.touchedInRecords(targets, true)
    );
  }
}
