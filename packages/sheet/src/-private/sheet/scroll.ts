/** Scrolling: the scroll element, its bounds, and revealing a cell (V03C-DESIGN.md 3.2). */
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { next, run } from '@ember/runloop';
import { modifier } from 'ember-modifier';

import { afterRender, samePos } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos, RecordId } from '../../core/index.ts';
import type { ScrollBounds } from '../auto-scroll.ts';

export default class SheetScroll<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The cell `followMatch` last scrolled to (`recordId` and `fieldId`), so a re-render does not scroll again. */
  lastMatch: string | null = null;

  /** The grid is scrolled horizontally (the frozen edge's shadow). */
  @tracked scrolledX = false;
  /**
   * Changes when the grid's columns or its layout change: the parts placed
   * over the grid (outlines, fill handle, selection handles) measure again.
   * A scroll places them without it (`placeOnScroll`).
   */
  @tracked layoutTick = 0;

  /**
   * The parts placed over the grid that are shown, each one's placing
   * (READINESS.md, Performance, step 2): a scroll places them again after
   * its render, without a tracked write, which would make every rendered
   * cell revalidate on every scroll step.
   */
  placers = new Set<() => void>();

  /** Registers a part's placing for the grid's scrolls and late layout changes; returns its removal. */
  placeOnScroll(place: () => void): () => void {
    this.placers.add(place);
    this.watchLayout();
    return () => {
      this.placers.delete(place);
      if (!this.placers.size) this.unwatchLayout();
    };
  }

  /**
   * While a part is shown: the grid's content box (its columns' widths and
   * its rows' heights), observed. The grid changes it after the render the
   * parts were placed on (READINESS.md item 5): it sizes its columns again
   * a frame later (the scroll bar measured), and gives the rows a new
   * `@rowHeight` after a render too, so a part placed on that render was a
   * pixel or two off (TR1's one failure) or a row-height difference above
   * its cell (the fill handle). A resize places every part again, without
   * a tracked write.
   */
  layoutObserver: ResizeObserver | null = null;
  observedContent: Element | null = null;

  watchLayout(): void {
    if (typeof ResizeObserver === 'undefined') return;
    // the grid's inner box, sized to its columns and rows
    const content = this.scrollElement()?.firstElementChild ?? null;
    if (content === this.observedContent) return;
    this.layoutObserver ??= new ResizeObserver(() => {
      if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
      this.placeAll();
    });
    if (this.observedContent) {
      this.layoutObserver.unobserve(this.observedContent);
    }
    this.observedContent = content;
    if (content) this.layoutObserver.observe(content);
  }

  unwatchLayout(): void {
    this.layoutObserver?.disconnect();
    this.observedContent = null;
  }

  /** Places every registered part again. */
  placeAll = (): void => {
    for (const place of this.placers) place();
  };

  /** The grid's scroll element. */
  scrollElement(): HTMLElement | null {
    return (
      this.sheet.wrapper?.querySelector<HTMLElement>(
        '.euiDataGrid__virtualized'
      ) ?? null
    );
  }

  /**
   * The grid body's visible area, in viewport px: inside the scroll bars,
   * below the sticky header and above the footer; `frozenRight` is where
   * the frozen columns end.
   */
  scrollBounds(): ScrollBounds | null {
    const outer = this.scrollElement();
    if (!outer) return null;
    const box = outer.getBoundingClientRect();
    const scale = outer.offsetWidth ? box.width / outer.offsetWidth : 1;
    const header = outer.querySelector<HTMLElement>(
      '[data-test-subj=dataGridHeader]'
    );
    const footer = outer.querySelector<HTMLElement>('.euiDataGridFooter');
    const left = box.left + outer.clientLeft * scale;
    const top = box.top + outer.clientTop * scale;
    const layout = this.sheet.frozen.frozenLayout;
    return {
      top: top + (header?.offsetHeight ?? 0) * scale,
      bottom: top + (outer.clientHeight - (footer?.offsetHeight ?? 0)) * scale,
      left,
      right: left + outer.clientWidth * scale,
      frozenRight: layout ? left + layout.right * scale : undefined
    };
  }

  /**
   * Whether a cell is rendered and in view: inside the body's visible area
   * and, unless it is frozen, not under the frozen columns (1 px slack).
   */
  cellInView(pos: Pos): HTMLElement | null {
    const cell = this.sheet.dom.cellElement(pos);
    const bounds = cell && this.scrollBounds();
    if (!cell || !bounds) return null;
    const box = cell.getBoundingClientRect();
    const left =
      bounds.frozenRight !== undefined &&
      pos.col >= this.sheet.frozen.frozenCount
        ? bounds.frozenRight
        : bounds.left;
    const inside =
      box.top >= bounds.top - 1 &&
      box.bottom <= bounds.bottom + 1 &&
      box.left >= left - 1 &&
      box.right <= bounds.right + 1;
    return inside ? cell : null;
  }

  /** Scrolls the grid by `dx`, `dy` px; whether it moved. */
  scrollGridBy(dx: number, dy: number): boolean {
    const outer = this.scrollElement();
    if (!outer || !this.sheet.gridApi?.scrollTo) return false;
    const { scrollLeft, scrollTop } = outer;
    run(() => {
      this.sheet.gridApi?.scrollTo?.({
        scrollLeft: Math.max(0, scrollLeft + dx),
        scrollTop: Math.max(0, scrollTop + dy)
      });
    });
    return (
      Math.abs(outer.scrollLeft - scrollLeft) > 0.5 ||
      Math.abs(outer.scrollTop - scrollTop) > 0.5
    );
  }

  /**
   * Scrolls a cell fully into the body's visible area (below the sticky
   * header, right of the frozen columns) without focusing it. A cell that
   * is not rendered is first brought near with the grid's `scrollToItem`,
   * then placed once rendered (a few frames at most).
   */
  revealCell(
    pos: Pos,
    wanted: () => boolean = () => samePos(this.sheet.selection.head, pos),
    attempts = 4
  ): void {
    const place = (): boolean => {
      const cell = this.sheet.dom.cellElement(pos);
      const bounds = this.scrollBounds();
      const outer = this.scrollElement();
      if (!cell || !bounds || !outer) return false;
      const box = cell.getBoundingClientRect();
      const outerBox = outer.getBoundingClientRect();
      const scale = outer.offsetWidth ? outerBox.width / outer.offsetWidth : 1;
      const left =
        bounds.frozenRight !== undefined &&
        pos.col >= this.sheet.frozen.frozenCount
          ? bounds.frozenRight
          : bounds.left;
      let dx = 0;
      let dy = 0;
      if (box.bottom > bounds.bottom + 0.5) dy = box.bottom - bounds.bottom;
      else if (box.top < bounds.top - 0.5) dy = box.top - bounds.top;
      if (pos.col >= this.sheet.frozen.frozenCount) {
        if (box.right > bounds.right + 0.5) dx = box.right - bounds.right;
        else if (box.left < left - 0.5) dx = box.left - left;
      }
      if (dx || dy) this.scrollGridBy(dx / scale, dy / scale);
      return true;
    };
    if (place()) return;
    if (attempts === 4) {
      this.sheet.gridApi?.scrollToItem?.({
        rowIndex: pos.row,
        columnIndex: pos.col + this.sheet.colOffset
      });
    }
    if (attempts <= 0) return;
    requestAnimationFrame(() => {
      if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
      if (!wanted()) return;
      this.revealCell(pos, wanted, attempts - 1);
    });
  }

  /* Search navigation (V03 11.1) */

  /** The grid position of a record's field, or null when the record is not in `@records` or the field is not shown. */
  posOfCell(cell: { recordId: RecordId; fieldId: string }): Pos | null {
    const row = this.sheet.rows.rowOf(cell.recordId, 0);
    const col = this.sheet.fields.visibleFields.findIndex(
      (field) => field.id === cell.fieldId
    );
    if (row < 0 || col < 0) return null;
    return { row: this.sheet.rows.gridRowOf(row), col };
  }

  /** `@currentMatch`'s cell, when it is drawn: in `@records` and a visible field. */
  @cached
  get matchPos(): Pos | null {
    const match = this.sheet.args.currentMatch;
    return match ? this.posOfCell(match) : null;
  }

  /** `SheetApi.scrollToCell`: into view, without focus or a selection change. */
  scrollToCell(cell: { recordId: RecordId; fieldId: string }): void {
    const pos = this.posOfCell(cell);
    if (!pos) return;
    // a later frame places it while the cell is still there
    this.revealCell(pos, () => samePos(this.posOfCell(cell), pos));
  }

  /**
   * Scrolls `@currentMatch` into view once per cell, after the render
   * that shows it: when it changes, or when its record arrives in
   * `@records` (the owner expanded its group or changed the page).
   */
  followMatch = modifier(() => {
    const match = this.sheet.args.currentMatch;
    const pos = this.matchPos;
    if (!match || !pos) {
      this.lastMatch = null;
      return;
    }
    const key = `${String(match.recordId)}\u0000${match.fieldId}`;
    if (key === this.lastMatch) return;
    this.lastMatch = key;
    afterRender(this.sheet, () => this.scrollToCell(match));
  });

  /** Whether the grid has rows out of view (its body scrolls up or down). */
  scrollsVertically(): boolean {
    const outer = this.scrollElement();
    return !!outer && outer.scrollHeight > outer.clientHeight + 1;
  }

  /** The rows fully in view: what PageUp and PageDown move by (at least 1). */
  pageRows(): number {
    const bounds = this.scrollBounds();
    if (!bounds || !this.sheet.wrapper) return 1;
    const rows = new Set<string>();
    for (const cell of this.sheet.wrapper.querySelectorAll<HTMLElement>(
      '[role=gridcell][data-gridcell-visible-row-index]'
    )) {
      if (cell.classList.contains('euiDataGridFooterCell')) continue;
      const row = cell.dataset['gridcellVisibleRowIndex']!;
      if (rows.has(row)) continue;
      const box = cell.getBoundingClientRect();
      if (box.top >= bounds.top - 1 && box.bottom <= bounds.bottom + 1) {
        rows.add(row);
      }
    }
    return Math.max(1, rows.size);
  }

  @action
  onScroll(event: Event): void {
    // the editor scrolling its own content is not a grid scroll
    if (this.sheet.dom.isInEditor(event.target)) return;
    const target = event.target;
    if (
      target instanceof HTMLElement &&
      target.classList.contains('euiDataGrid__virtualized')
    ) {
      // a grid scroll cancels the field editor (V03 6.4)
      if (this.sheet.fieldEditor.fieldEditorState)
        this.sheet.fieldEditor.closeFieldEditor(false);
      const scrolledX = target.scrollLeft > 0;
      if (scrolledX !== this.scrolledX) this.scrolledX = scrolledX;
      // after the grid rendered the rows of this scroll (V03 batch 1)
      if (this.sheet.focus.gridHadFocus && this.sheet.selection.anchor) {
        afterRender(this.sheet, this.sheet.focus.parkFocus);
        next(this.sheet.focus.parkFocus);
      }
      // a key's focus move restored its scroll in the same task; a later
      // scroll (wheel, scrollbar) must not be undone by a stale value
      if (!this.sheet.frozen.pressing)
        this.sheet.frozen.scrollLeftBeforeFocus = null;
    }
    // an editor whose cell is still fully in view follows it (the grid's
    // scroll that brings a just-focused cell into view arrives a frame
    // later); else it saves and closes, before a stale position shows and
    // before the re-mounted focused cell can pull focus
    const editing = this.sheet.edit.editing;
    if (editing) {
      const cell = this.cellInView(editing.pos);
      const rect = cell && this.sheet.dom.rectOf(cell);
      if (rect) editing.rect = rect;
      else this.sheet.edit.commit({ refocus: false });
    }
    // the catcher follows its cell the same way (the far column's late
    // scroll comes between a dead key and its character); out of view it
    // ends, and focus does not stay on a hidden input
    const imePos = this.sheet.ime.imePos;
    if (imePos) {
      const cell = this.cellInView(imePos);
      const rect = cell && this.sheet.dom.rectOf(cell);
      if (rect) {
        this.sheet.ime.placeIme(rect);
      } else if (!this.sheet.ime.imeComposing) {
        const input = this.sheet.ime.imeInput;
        this.sheet.ime.endIme();
        input?.blur();
      }
    }
    if (this.sheet.rowMenu.menu) this.sheet.rowMenu.closeMenu(false);
    // the parts over the grid follow, after the render of this scroll
    if (this.placers.size) afterRender(this.sheet, this.placeAll);
    // the error box follows its cell, or hides while the cell is not rendered
    const focused = this.sheet.focus.focused;
    if (focused) {
      const cell = this.sheet.dom.dataCell(document.activeElement);
      if (cell && samePos(this.sheet.dom.cursor(cell), focused.pos)) {
        this.sheet.focus.trackFocusedCell(focused.pos, cell);
      } else {
        this.sheet.focus.focused = null;
      }
    }
  }
}
