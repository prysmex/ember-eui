/** Press and drag: selecting a range with the mouse, auto-scroll (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import AutoScroll from '../auto-scroll.ts';
import { samePos } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos } from '../../core/index.ts';

export default class SheetDrag<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** A drag over other cells is selecting a range (no text selection meanwhile). */
  @tracked dragging = false;
  /** The last pointer position of a drag, in viewport px. */
  dragPointer: { x: number; y: number } | null = null;
  /** The drags' auto-scroll loop. */
  autoScroll = new AutoScroll({
    bounds: () => this.sheet.scroll.scrollBounds(),
    scrollBy: (dx, dy) => this.sheet.scroll.scrollGridBy(dx, dy),
    onFrame: (x, y) => this.dragTo(x, y)
  });
  /** What a drag selects: cells, or rows (a press on a row number). */
  dragKind: 'cells' | 'rows' = 'cells';

  /** The cell a left-button press started on, while it may become a drag. */
  dragFrom: Pos | null = null;
  /** The press ended a drag: its click is not a click on a cell. */
  suppressClick = false;

  /** The press started on the cell that already had focus (a second click edits). */
  pressOnFocusedCell = false;

  @action
  onMouseDown(event: MouseEvent): void {
    // the compatibility mouse events of the long press that opened the menu
    if (this.sheet.touch.longPressOpened) return;
    this.sheet.focus.extending = event.shiftKey;
    this.sheet.frozen.noteScrollLeft();
    this.sheet.frozen.pressing = true;
    const target = event.target as Element;
    // before the press moves focus: was this cell the focused one?
    const cell = this.sheet.dom.dataCell(target);
    this.pressOnFocusedCell = !!cell && cell === document.activeElement;
    // the active cell stays focused through a range (V03 batch 1): a plain
    // press on it collapses the range, as a press on another cell would,
    // and is not a second click that edits
    if (
      this.pressOnFocusedCell &&
      event.button === 0 &&
      !event.shiftKey &&
      this.sheet.selection.anchor &&
      this.sheet.selection.head &&
      !samePos(this.sheet.selection.anchor, this.sheet.selection.head)
    ) {
      this.pressOnFocusedCell = false;
      const pos = this.sheet.dom.cursor(cell!);
      this.sheet.selection.anchor = pos;
      this.sheet.selection.head = pos;
      this.sheet.selection.rangeKind = 'cells';
    }
    // a click after a drag that released outside the sheet never came
    this.suppressClick = false;
    this.endDrag();
    if (this.sheet.rowMenu.menu && !this.sheet.dom.isInMenu(target))
      this.sheet.rowMenu.closeMenu(false);

    const rowCell = this.sheet.dom.rowNumberCell(target);
    if (rowCell) {
      // the range is the press's: focusin must not clear it
      this.sheet.focus.keepRangeOnFocus = true;
      const row = this.sheet.dom.rowIndexOf(rowCell);
      // a group header keeps no range (V03 8.6), also after a press on
      // its row number with a range elsewhere: a paste there writes nothing
      if (
        this.sheet.rows.isGrouped &&
        this.sheet.rows.rowKind(row) === 'group'
      ) {
        this.sheet.focus.keepRangeOnFocus = false;
      }
      if (!this.sheet.rows.isRecordRow(row) || event.button !== 0) return;
      // the checkbox and the expand icon are buttons, not a selection
      if (
        target.closest(
          '[data-eui-sheet-row-check], [data-eui-sheet-row-expand]'
        )
      ) {
        return;
      }
      this.sheet.selection.selectRows(row, event.shiftKey);
      if (
        !event.shiftKey &&
        !this.sheet.edit.editing &&
        this.sheet.touch.lastPointerType !== 'touch'
      ) {
        this.dragFrom = { row, col: 0 };
        this.dragKind = 'rows';
        this.watchRelease();
      }
      return;
    }

    if (!cell) return;
    const pos = this.sheet.dom.cursor(cell);
    if (event.button === 2) {
      // a right-click inside the range keeps it for the menu
      this.sheet.focus.keepRangeOnFocus = this.sheet.selection.isSelected(
        pos.row,
        pos.col
      );
      return;
    }
    // Shift+click extends the range; focus stays on the active cell (the
    // anchor), so the press must not move it (V03 batch 1)
    if (
      event.button === 0 &&
      event.shiftKey &&
      !this.sheet.edit.editing &&
      this.sheet.selection.rangeKind === 'cells' &&
      this.sheet.rows.isRecordRow(pos.row) &&
      this.sheet.dom.dataCell(document.activeElement)
    ) {
      event.preventDefault();
      this.sheet.selection.extendHead(pos);
      return;
    }
    // a press that may become a drag (Shift+click extends instead)
    // (a touch drag scrolls: no range drag by touch, 8.5)
    if (
      event.button === 0 &&
      !event.shiftKey &&
      !this.sheet.edit.editing &&
      this.sheet.touch.lastPointerType !== 'touch' &&
      this.sheet.rows.isRecordRow(pos.row) &&
      !target.closest('[data-eui-sheet-opener]')
    ) {
      this.dragFrom = pos;
      this.dragKind = 'cells';
      this.watchRelease();
    }
  }

  /** A press that may become a select drag: its release, and the pointer for auto-scroll. */
  watchRelease(): void {
    document.addEventListener('mouseup', this.onRelease, true);
    document.addEventListener('mousemove', this.onDragMove, true);
  }

  /** The pointer during a select drag: auto-scroll near the grid's edges (8.4). */
  onDragMove = (event: MouseEvent): void => {
    if (!this.dragFrom) return;
    this.dragPointer = { x: event.clientX, y: event.clientY };
    this.feedAutoScroll(event.clientX, event.clientY, this.dragging);
  };

  /**
   * Passes the pointer to the auto-scroll loop once a drag is really
   * selecting (or filling), or the pointer left the grid's body: a plain
   * press near an edge, with a pixel of jitter, must not scroll.
   */
  feedAutoScroll(x: number, y: number, active: boolean): void {
    if (active || this.autoScroll.running) {
      this.autoScroll.update(x, y);
      return;
    }
    const bounds = this.sheet.scroll.scrollBounds();
    if (
      bounds &&
      (x < bounds.left ||
        x > bounds.right ||
        y < bounds.top ||
        y > bounds.bottom)
    ) {
      this.autoScroll.update(x, y);
    }
  }

  /**
   * An auto-scroll frame (or a fill drag's move): the cell under the
   * pointer, clamped inside the grid's body, is the drag's head. Rows the
   * scroll rendered under a pointer that did not move fire no `mouseover`.
   */
  dragTo(x: number, y: number): void {
    const element = document.elementFromPoint(x, y);
    if (this.sheet.filling.fillSource) this.sheet.filling.fillTo(element);
    else if (this.dragFrom) this.dragOver(element);
  }

  /**
   * Drag to select: once the pointer is over another data cell, the pressed
   * cell is the anchor and the hovered one the head. Nothing changes while
   * the pointer stays on the pressed cell, so a click is only a click. A
   * press on a row number drags whole rows.
   */
  @action
  onMouseOver(event: MouseEvent): void {
    this.dragOver(event.target);
  }

  /** A select drag reached `element` (a `mouseover`, or an auto-scroll frame). */
  dragOver(element: EventTarget | null): void {
    const from = this.dragFrom;
    if (!from) return;
    if (this.dragKind === 'rows') {
      const target =
        this.sheet.dom.rowNumberCell(element) ??
        this.sheet.dom.dataCell(element);
      if (!target) return;
      const row = this.sheet.dom.rowIndexOf(target);
      if (!this.sheet.rows.isRecordRow(row)) return;
      if (!this.dragging) {
        if (row === from.row) return;
        this.dragging = true;
      }
      this.sheet.selection.selectRows(row, true);
      window.getSelection()?.removeAllRanges();
      return;
    }
    const cell = this.sheet.dom.dataCell(element);
    if (!cell) return;
    const pos = this.sheet.dom.cursor(cell);
    // the add row is never part of a range
    if (!this.sheet.rows.isRecordRow(pos.row)) return;
    if (!this.dragging) {
      if (samePos(pos, from)) return;
      this.dragging = true;
      this.sheet.selection.anchor = from;
      this.sheet.selection.rangeKind = 'cells';
    }
    if (!samePos(pos, this.sheet.selection.head))
      this.sheet.selection.head = pos;
    // text the press may have started to select
    window.getSelection()?.removeAllRanges();
  }

  /** The release ends a drag (anywhere on the page): focus stays on the anchor, the active cell (V03 batch 1). */
  onRelease = (): void => {
    const dragged = this.dragging;
    const kind = this.dragKind;
    const from = this.dragFrom;
    const before = this.sheet.frozen.scrollLeftBeforeFocus;
    this.endDrag();
    if (!dragged) return;
    // the grid scrolled the pressed cell into view on pointerup; a frozen
    // one is always in view, so the scroll goes back to the press's
    if (
      this.sheet.frozen.frozenCount &&
      (kind === 'rows' ||
        (from !== null && from.col < this.sheet.frozen.frozenCount))
    ) {
      this.sheet.frozen.scrollLeftBeforeFocus = before;
      this.sheet.frozen.keepFrozenScroll();
    }
    const head = this.sheet.selection.head;
    if (!head || samePos(head, this.sheet.selection.anchor)) return;
    // the click that follows is the end of the drag, not a click on a cell
    this.suppressClick = true;
    // the head may not be rendered now (an auto-scroll took it away, or the
    // grid's pointerup scrolled back to the pressed cell), so its focus can
    // come after this release and after its click: the focus handlers must
    // see a cell they already know and keep the range
    if (kind === 'rows') {
      const row = this.sheet.selection.anchor?.row ?? head.row;
      this.sheet.focus.keepRangeOnFocus = true;
      this.sheet.focus.rowCursor = row;
      this.sheet.dom.focusRowNumberCell(row);
      return;
    }
    // the press focused the anchor and the grid scrolled it back into view
    // on pointerup; focus it again only if something took focus away.
    // onFocusIn sees the cell it knows and keeps the range
    const anchor = this.sheet.selection.anchor;
    if (anchor && anchor.row < this.sheet.rows.rowCount) {
      this.sheet.focus.domCursor = anchor;
      const active = this.sheet.dom.dataCell(document.activeElement);
      if (!active || !samePos(this.sheet.dom.cursor(active), anchor)) {
        this.sheet.dom.focusGridCell(anchor);
      }
    }
  };

  endDrag(): void {
    this.stopWatchingRelease();
    this.dragFrom = null;
    if (this.dragging) this.dragging = false;
  }

  stopWatchingRelease(): void {
    document.removeEventListener('mouseup', this.onRelease, true);
    document.removeEventListener('mousemove', this.onDragMove, true);
    if (!this.sheet.filling.fillSource) {
      this.autoScroll.stop();
      this.dragPointer = null;
    }
  }
}
