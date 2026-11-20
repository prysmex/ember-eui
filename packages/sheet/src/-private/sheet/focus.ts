/** Focus tracking: the focused cell, the cursors, parking focus (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { next } from '@ember/runloop';
import { htmlSafe } from '@ember/template';

import { afterRender, samePos } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos } from '../../core/index.ts';
import type { FocusedCell } from './types.ts';

/** Room the focused cell's error box needs below the cell before it flips above. */
const CELL_ERROR_SPACE = 48;
/** The error box's widest size. */
const CELL_ERROR_MAX_WIDTH = 320;

export default class SheetFocus<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The data cell that has DOM focus, for its error box; null when focus is elsewhere. */
  @tracked focused: FocusedCell | null = null;
  /** A key would have edited this read-only cell: "Read only" in its message box until focus moves (V03 batch 2). */
  @tracked readOnlyCue: Pos | null = null;
  /** Last row-number cell seen by `focusin`. */
  rowCursor: number | null = null;
  /** The next focus on a cell keeps the range (a press set it, or a right-click inside it). */
  keepRangeOnFocus = false;
  /** Last data cell seen by `focusin`. */
  domCursor: Pos | null = null;
  /** The next focus move extends the range. */
  extending = false;

  /**
   * A press anywhere on the page, until the end of its task: a focus that
   * goes nowhere during it is the press's (a click on the page), not the
   * grid moving the focused cell (`onFocusOut`).
   */
  pagePressed = false;

  onPagePress = (): void => {
    if (this.pagePressed) return;
    this.pagePressed = true;
    next(() => (this.pagePressed = false));
  };

  /* -------------------------------------------------------------------- */
  /* Focus tracking                                                        */
  /* -------------------------------------------------------------------- */

  @action
  onFocusIn(event: FocusEvent): void {
    const keepRange = this.keepRangeOnFocus;
    this.keepRangeOnFocus = false;
    // a "+" column body cell (a click there, ArrowDown from its header) is
    // inert: focus goes to the row's last field (V03 6.12)
    const addCell = this.sheet.dom.addFieldCell(event.target);
    if (addCell && !addCell.classList.contains('euiDataGridFooterCell')) {
      const row = this.sheet.dom.rowIndexOf(addCell);
      const col = this.sheet.fields.visibleFields.length - 1;
      if (col >= 0 && row >= 0 && row < this.sheet.rows.rowCount) {
        this.sheet.selection.moveFocus({ row, col }, false);
      }
      return;
    }
    const rowCell = this.sheet.dom.rowNumberCell(event.target);
    // a header keeps no position: its key is what focus follows (V03 8.3)
    this.sheet.groupHeaders.noteGroupFocus(
      rowCell ?? this.sheet.dom.dataCell(event.target)
    );
    if (rowCell) {
      this.focused = null;
      if (this.sheet.frozen.frozenCount) this.sheet.frozen.onFrozenFocus(0);
      this.onRowNumberFocus(this.sheet.dom.rowIndexOf(rowCell), keepRange);
      return;
    }
    const cell = this.sheet.dom.dataCell(event.target);
    if (!cell) {
      this.sheet.frozen.scrollLeftBeforeFocus = null;
      // the header, a control or an editor: no error box (an open editor
      // hides it anyway)
      if (!this.sheet.dom.isInEditor(event.target)) this.focused = null;
      return;
    }
    const pos = this.sheet.dom.cursor(cell);
    this.rowCursor = null;
    // a group header (V03 9.1): focus only, no range to copy, clear or
    // paste over; the arrows move on through the grid
    if (this.sheet.rows.rowKind(pos.row) === 'group') {
      this.sheet.frozen.scrollLeftBeforeFocus = null;
      this.focused = null;
      this.readOnlyCue = null;
      this.domCursor = null;
      if (!keepRange) {
        this.sheet.selection.anchor = null;
        this.sheet.selection.head = null;
        this.sheet.selection.rangeKind = 'cells';
      }
      return;
    }
    this.gridHadFocus = true;
    if (this.readOnlyCue && !samePos(this.readOnlyCue, pos)) {
      this.readOnlyCue = null;
    }
    this.trackFocusedCell(pos, cell);
    if (this.sheet.frozen.frozenCount) {
      if (pos.col < this.sheet.frozen.frozenCount)
        this.sheet.frozen.onFrozenFocus(pos.col + this.sheet.colOffset);
      else
        afterRender(this.sheet, () =>
          this.sheet.frozen.clearFrozenOverlap(pos)
        );
    }
    // the grid re-focuses the same cell when it re-mounts (scroll) and
    // after cancel(): that must not collapse a range
    if (samePos(pos, this.domCursor)) return;
    this.domCursor = pos;
    // a right-click inside the range keeps it for the menu
    if (keepRange) return;
    if (this.extending && this.sheet.selection.anchor) {
      this.sheet.selection.head = pos;
    } else {
      this.sheet.selection.anchor = pos;
      this.sheet.selection.head = pos;
    }
    this.sheet.selection.rangeKind = 'cells';
  }

  /**
   * Focus on a row-number cell (C13): a press there already set the range
   * (`keepRange`); Shift+ArrowUp/Down extends a `'rows'` range; any other
   * keyboard focus clears the range, so Delete, copy and paste do nothing.
   */
  onRowNumberFocus(row: number, keepRange: boolean): void {
    // the grid re-focuses the same cell when it re-mounts (scroll)
    if (row === this.rowCursor) return;
    const from = this.rowCursor;
    this.rowCursor = row;
    this.domCursor = null;
    if (keepRange) return;
    const last = this.sheet.fields.visibleFields.length - 1;
    if (this.extending && this.sheet.rows.isRecordRow(row)) {
      if (
        this.sheet.selection.rangeKind !== 'rows' ||
        !this.sheet.selection.anchor
      ) {
        this.sheet.selection.anchor = { row: from ?? row, col: 0 };
        this.sheet.selection.rangeKind = 'rows';
      }
      this.sheet.selection.head = { row, col: last };
      return;
    }
    this.sheet.selection.anchor = null;
    this.sheet.selection.head = null;
    this.sheet.selection.rangeKind = 'cells';
  }

  /**
   * A data cell lost focus to nowhere in this run loop: a render removed
   * it (the owner dropped its row), or a click outside. `followRecords`
   * re-focuses the grid only in the first case.
   */
  focusDropped = false;

  /** Focus leaving the grid's data cells hides the error box. */
  @action
  onFocusOut(event: FocusEvent): void {
    const to = event.relatedTarget;
    // focus left the grid, or a render removed the focused cell (the
    // grid's virtualization): then it is parked (V03 batch 1)
    const target = event.target;
    if (to instanceof Node && !this.sheet.dom.ownsNode(to)) {
      this.gridHadFocus = false;
      this.sheet.groupHeaders.focusedGroup = null;
    } else if (!to && target instanceof Node) {
      // the grid re-inserting the focused cell's row (a scroll) blurs it
      // too, and the cell is connected again by then: without a press, with
      // focus on the body and the window focused, that is not focus leaving
      // the grid (P7's race: whether a later scroll parked it first)
      const pressed = this.pagePressed;
      next(() => {
        const moved =
          !pressed &&
          document.activeElement === document.body &&
          document.hasFocus();
        if (target.isConnected && !moved) this.gridHadFocus = false;
        else this.parkFocus();
      });
    }
    if (this.sheet.dom.dataCell(to) || this.sheet.dom.isInEditor(to)) return;
    this.focused = null;
    if (!to && this.sheet.dom.dataCell(event.target)) {
      this.focusDropped = true;
      next(() => (this.focusDropped = false));
    }
    // a header cell (data or row number) whose row a render removed
    if (
      !to &&
      this.sheet.groupHeaders.focusedGroup &&
      (this.sheet.dom.dataCell(target) ?? this.sheet.dom.rowNumberCell(target))
    ) {
      this.sheet.groupHeaders.groupFocusDropped = true;
      next(() => (this.sheet.groupHeaders.groupFocusDropped = false));
    }
  }

  trackFocusedCell(pos: Pos, cell: HTMLElement): void {
    const rect = this.sheet.dom.rectOf(cell);
    if (!rect || !this.sheet.wrapper) return;
    this.focused = {
      pos,
      rect,
      wrapperWidth: this.sheet.wrapper.offsetWidth,
      viewportBelow: window.innerHeight - cell.getBoundingClientRect().bottom
    };
  }

  /**
   * The focused cell's errors, shown next to it while it has focus and no
   * editor is open (the cell's `title` has them too, on hover).
   */
  get cellError(): {
    messages: string[];
    placement: 'below' | 'above';
    style: ReturnType<typeof htmlSafe>;
    /** Not an error: the read-only cue (V03 batch 2). */
    notice: boolean;
  } | null {
    const focused = this.focused;
    if (
      !focused ||
      this.sheet.edit.editing ||
      this.sheet.rowMenu.menu ||
      this.sheet.ime.imeActive
    )
      return null;
    const field = this.sheet.fields.visibleFields[focused.pos.col];
    if (!field) return null;
    const view = this.sheet.cells.cellView(
      focused.pos.row,
      focused.pos.col,
      field.id
    );
    if (!view) return null;
    const notice =
      view.errors.length === 0 && samePos(this.readOnlyCue, focused.pos);
    if (view.errors.length === 0 && !notice) return null;
    const { rect, wrapperWidth, viewportBelow } = focused;
    // the box may hang below the sheet; it flips only near the window's bottom
    const placement = viewportBelow < CELL_ERROR_SPACE ? 'above' : 'below';
    const vertical =
      placement === 'above'
        ? `bottom:${rect.wrapperHeight - rect.top + 2}px;`
        : `top:${rect.top + rect.height + 2}px;`;
    const left = Math.max(
      0,
      Math.min(rect.left, wrapperWidth - CELL_ERROR_MAX_WIDTH)
    );
    return {
      messages: notice ? [this.sheet.messages.cellReadOnly()] : view.errors,
      placement,
      notice,
      style: htmlSafe(
        `left:${left}px;max-width:${CELL_ERROR_MAX_WIDTH}px;${vertical}`
      )
    };
  }

  /**
   * The grid's body element while it holds focus for an active cell that
   * scrolled out of the rendered rows or columns (`parkFocus`).
   */
  isParked(target: EventTarget | null): boolean {
    return (
      target instanceof Element &&
      target.matches('[role=grid]') &&
      !!this.sheet.wrapper?.contains(target) &&
      !!this.sheet.selection.anchor &&
      this.sheet.selection.rangeKind === 'cells'
    );
  }

  /** A data cell (or the parked grid body) had focus, and focus has not left the grid since. */
  gridHadFocus = false;

  /**
   * After a scroll: the focused active cell was removed by the grid's
   * virtualization while a range is selected (it was extended away from
   * it, or the user scrolled), so focus fell to the page and the keys with
   * it. The grid's body holds focus until the cell is rendered again (the
   * grid focuses it then); keys pressed meanwhile act on the range
   * (`onParkedKeyDown`).
   */
  parkFocus = (): void => {
    if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
    const anchor = this.sheet.selection.anchor;
    if (
      !this.gridHadFocus ||
      !anchor ||
      this.sheet.selection.rangeKind !== 'cells'
    )
      return;
    if (samePos(anchor, this.sheet.selection.head)) return;
    const active = document.activeElement;
    if (active && active !== document.body) return;
    // rendered again already (the grid re-created it): the cell itself
    const cell = this.sheet.dom.cellElement(anchor);
    this.domCursor = anchor;
    if (cell) {
      cell.focus({ preventScroll: true });
      return;
    }
    const grid = this.sheet.wrapper?.querySelector<HTMLElement>('[role=grid]');
    grid?.focus({ preventScroll: true });
  };
}
