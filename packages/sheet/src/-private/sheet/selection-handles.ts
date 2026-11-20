/**
 * Ranges by touch (V03 11.3, D12): two handles on the range's corners
 * after a touch press. Dragging one moves that corner; a drag on the grid
 * stays a scroll and a long press stays the menu.
 */
import { tracked } from '@glimmer/tracking';

import AutoScroll from '../auto-scroll.ts';
import { samePos } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos, Range } from '../../core/index.ts';

/** The handle's hit area in px (`styles.ts`): a 20 px circle in a 44 px box. */
const HIT_SIZE = 44;

export type HandleCorner = 'start' | 'end';

export default class SheetSelectionHandles<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The last press was a touch: the handles show (a mouse on a hybrid device never sees them). */
  @tracked byTouch = false;
  /** A handle drag: which corner moves, the corner that stays, and its pointer. */
  handleDrag: { corner: HandleCorner; fixed: Pos; pointerId: number } | null =
    null;
  /** A handle is being dragged: the handles let the pointer through to the cells under them. */
  @tracked dragging = false;
  /** The drag's auto-scroll loop near the grid's edges. */
  autoScroll = new AutoScroll({
    bounds: () => this.sheet.scroll.scrollBounds(),
    scrollBy: (dx, dy) => this.sheet.scroll.scrollGridBy(dx, dy),
    onFrame: (x, y) => this.moveTo(x, y)
  });

  /** A press on the sheet (`touch.onPointerDown`): its pointer type. */
  notePress(pointerType: string): void {
    const touch = pointerType === 'touch';
    if (touch !== this.byTouch) this.byTouch = touch;
  }

  /** The range the handles are drawn for: a cell range with records, after a touch, no editor. */
  get range(): Range | null {
    if (!this.byTouch || this.sheet.edit.editing) return null;
    const range = this.sheet.selection.range;
    if (!range || this.sheet.selection.rangeKind !== 'cells') return null;
    return this.sheet.rows.recordRange(range) ? range : null;
  }

  /** The grid position of a corner: the first or the last record's row of the range. */
  cornerOf(range: Range, corner: HandleCorner): Pos | null {
    const records = this.sheet.rows.recordRange(range);
    if (!records) return null;
    return corner === 'start'
      ? { row: this.sheet.rows.gridRowOf(records.top), col: range.left }
      : { row: this.sheet.rows.gridRowOf(records.bottom), col: range.right };
  }

  /** Puts a handle on its corner (as the fill handle is placed), or hides it while that corner is not in view. */
  place(element: HTMLElement, range: Range, corner: HandleCorner): void {
    const pos = this.cornerOf(range, corner);
    const cell = pos && this.sheet.dom.cellElement(pos);
    const bounds = cell && this.sheet.scroll.scrollBounds();
    const rect = cell && this.sheet.dom.rectOf(cell);
    let shown = false;
    if (pos && cell && bounds && rect) {
      const box = cell.getBoundingClientRect();
      const x = corner === 'start' ? box.left : box.right;
      const y = corner === 'start' ? box.top : box.bottom;
      // under the frozen columns counts as out of view
      const left =
        bounds.frozenRight !== undefined &&
        pos.col >= this.sheet.frozen.frozenCount
          ? bounds.frozenRight
          : bounds.left;
      shown =
        x >= left - 1 &&
        x <= bounds.right + 1 &&
        y >= bounds.top - 1 &&
        y <= bounds.bottom + 1;
      if (shown) {
        const half = HIT_SIZE / 2;
        const top = corner === 'start' ? rect.top : rect.top + rect.height;
        const leftPx = corner === 'start' ? rect.left : rect.left + rect.width;
        element.style.top = `${top - half}px`;
        element.style.left = `${leftPx - half}px`;
      }
    }
    element.style.display = shown ? '' : 'none';
  }

  /** A press on a handle starts its drag; focus stays where it is. */
  onHandleDown = (corner: HandleCorner, event: PointerEvent): void => {
    // no compatibility mouse events, no text selection
    event.preventDefault();
    event.stopPropagation();
    const range = this.range;
    if (!range || this.handleDrag) return;
    const start = this.cornerOf(range, 'start');
    const end = this.cornerOf(range, 'end');
    if (!start || !end) return;
    // the bottom-right handle moves the head, the top-left the anchor
    this.handleDrag = {
      corner,
      fixed: corner === 'end' ? start : end,
      pointerId: event.pointerId
    };
    this.dragging = true;
    this.sheet.selection.anchor = start;
    this.sheet.selection.head = end;
    this.sheet.selection.rangeKind = 'cells';
    try {
      (event.currentTarget as Element | null)?.setPointerCapture(
        event.pointerId
      );
    } catch {
      // a pointer the browser does not know (a synthetic event)
    }
    document.addEventListener('pointermove', this.onHandleMove, true);
    document.addEventListener('pointerup', this.onHandleUp, true);
    document.addEventListener('pointercancel', this.onHandleUp, true);
  };

  onHandleMove = (event: PointerEvent): void => {
    const drag = this.handleDrag;
    if (!drag || event.pointerId !== drag.pointerId) return;
    event.preventDefault();
    this.moveTo(event.clientX, event.clientY);
    this.autoScroll.update(event.clientX, event.clientY);
  };

  /** The dragged corner reaches the record cell under a point (headers and add rows are skipped). */
  moveTo(x: number, y: number): void {
    const drag = this.handleDrag;
    if (!drag) return;
    const cell = this.sheet.dom.dataCell(document.elementFromPoint(x, y));
    if (!cell) return;
    const pos = this.sheet.dom.cursor(cell);
    if (!this.sheet.rows.isRecordRow(pos.row)) return;
    const selection = this.sheet.selection;
    if (drag.corner === 'end') {
      if (!samePos(selection.anchor, drag.fixed)) selection.anchor = drag.fixed;
      if (!samePos(selection.head, pos)) selection.head = pos;
    } else {
      if (!samePos(selection.anchor, pos)) selection.anchor = pos;
      if (!samePos(selection.head, drag.fixed)) selection.head = drag.fixed;
    }
  }

  /** The release (or a cancel) ends the drag; the anchor, the active cell, gets focus if it moved. */
  onHandleUp = (event: PointerEvent): void => {
    const drag = this.handleDrag;
    if (!drag || event.pointerId !== drag.pointerId) return;
    this.end();
    const anchor = this.sheet.selection.anchor;
    if (!anchor) return;
    const active = this.sheet.dom.dataCell(document.activeElement);
    if (active && samePos(this.sheet.dom.cursor(active), anchor)) return;
    // onFocusIn sees the cell it knows and keeps the range
    this.sheet.focus.domCursor = anchor;
    this.sheet.dom.focusGridCell(anchor);
  };

  end(): void {
    this.handleDrag = null;
    if (this.dragging) this.dragging = false;
    this.autoScroll.stop();
    document.removeEventListener('pointermove', this.onHandleMove, true);
    document.removeEventListener('pointerup', this.onHandleUp, true);
    document.removeEventListener('pointercancel', this.onHandleUp, true);
  }
}
