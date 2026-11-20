/** The frozen fields: their layout, classes and scroll (V03C-DESIGN.md 3.2). */
import { cached } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { htmlSafe } from '@ember/template';

import { afterRender } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos } from '../../core/index.ts';
import type { FrozenLayout } from './types.ts';

/**
 * The frozen field (V02-DESIGN.md 9): above this many visible fields the
 * sheet stops freezing (it renders every column of the rendered rows while
 * a field is frozen).
 */
const FROZEN_MAX_COLUMNS = 50;

export default class SheetFrozen<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /* The frozen field (V02-DESIGN.md 6.7, 9.2) */

  /** How many leading fields are frozen: `@frozenFields` (default 0, opt-in), 0 above FROZEN_MAX_COLUMNS fields. */
  @cached
  get frozenCount(): number {
    const count = this.sheet.fields.visibleFields.length;
    const wanted = this.sheet.args.frozenFields ?? 0;
    if (wanted <= 0 || count === 0) return 0;
    if (count > FROZEN_MAX_COLUMNS) {
      warn(
        `EuiSheet: ${count} visible fields: frozen fields are off above ${FROZEN_MAX_COLUMNS} (every column of the rendered rows would be rendered).`,
        false,
        { id: 'ember-eui.sheet.frozen-fields-off' }
      );
      return 0;
    }
    return Math.min(wanted, count);
  }

  @cached
  get frozenLayout(): FrozenLayout | null {
    const frozen = this.frozenCount;
    if (!frozen) return null;
    const lefts = new Map<number, number>();
    let left = 0;
    if (this.sheet.colOffset) {
      lefts.set(0, 0);
      left += this.sheet.gridColumns.rowColumnWidth;
    }
    const fields = this.sheet.fields.visibleFields;
    for (let i = 0; i < frozen; i++) {
      lefts.set(i + this.sheet.colOffset, left);
      left += this.sheet.gridColumns.frozenWidth(fields[i]!);
    }
    return { lefts, last: frozen - 1 + this.sheet.colOffset, right: left };
  }

  frozenHeaderClass(colIndex: number): string {
    const last = this.frozenCount - 1 + this.sheet.colOffset;
    return `euiSheet__frozenHeader euiSheet__frozenHeader--${colIndex}${colIndex === last ? ' euiSheet__frozenEdge' : ''}`;
  }

  /**
   * The style and class of a frozen body cell (`footer`: a footer cell),
   * or null: sticky at its `left`, floated so two sit side by side in the
   * absolute row; footer cells are flex items, so no float (9.2).
   */
  frozenCellProps(
    colIndex: number,
    footer = false
  ): { className: string; style: Record<string, string | number> } | null {
    const layout = this.frozenLayout;
    const left = layout?.lefts.get(colIndex);
    if (!layout || left === undefined) return null;
    const style: Record<string, string | number> = footer
      ? { position: 'sticky', left, zIndex: 2 }
      : { position: 'sticky', float: 'left', left, zIndex: 2 };
    const className =
      colIndex === layout.last
        ? 'euiSheet__cell--frozen euiSheet__frozenEdge'
        : 'euiSheet__cell--frozen';
    return { className, style };
  }

  /** The frozen header cells' `left`s, as custom properties on the grid's container. */
  @cached
  get frozenStyle(): ReturnType<typeof htmlSafe> | undefined {
    const layout = this.frozenLayout;
    if (!layout) return undefined;
    return htmlSafe(
      [...layout.lefts]
        .map(([index, left]) => `--euiSheetFrozenLeft-${index}:${left}px`)
        .join(';')
    );
  }

  /**
   * The grid scrolls a focused cell into view by its own left edge, which
   * may leave it under the frozen columns (ArrowLeft). After the focus, the
   * sheet scrolls it clear (9.1).
   */
  clearFrozenOverlap(pos: Pos): void {
    const layout = this.frozenLayout;
    if (!layout || pos.col < this.frozenCount) return;
    const outer = this.sheet.scroll.scrollElement();
    const cell = this.sheet.dom.cellElement(pos);
    if (!outer || !cell) return;
    const box = outer.getBoundingClientRect();
    const scale = outer.offsetWidth ? box.width / outer.offsetWidth : 1;
    const cellLeft =
      (cell.getBoundingClientRect().left - box.left) / scale - outer.clientLeft;
    const overlap = layout.right - cellLeft;
    if (overlap > 0.5) {
      this.sheet.gridApi?.scrollTo?.({
        scrollLeft: Math.max(0, outer.scrollLeft - overlap)
      });
    }
  }

  /**
   * The grid's horizontal scroll before a focus move made by a key, a press
   * or the sheet itself; null otherwise. A frozen cell is always in view,
   * but the grid scrolls to its column's left edge when it gets focus
   * (ArrowLeft into the first field, a click on it while scrolled): the
   * sheet puts the scroll back once (`keepFrozenScroll`).
   */
  scrollLeftBeforeFocus: number | null = null;
  /** A press is in progress: the grid scrolls the pressed cell into view on pointerup, so the click restores. */
  pressing = false;

  noteScrollLeft(): void {
    if (!this.frozenCount) return;
    this.scrollLeftBeforeFocus =
      this.sheet.scroll.scrollElement()?.scrollLeft ?? null;
  }

  keepFrozenScroll(): void {
    const before = this.scrollLeftBeforeFocus;
    this.scrollLeftBeforeFocus = null;
    if (before === null || !this.frozenCount) return;
    const outer = this.sheet.scroll.scrollElement();
    if (outer && Math.abs(outer.scrollLeft - before) > 0.5) {
      this.sheet.gridApi?.scrollTo?.({ scrollLeft: before });
    }
  }

  /** Focus reached a frozen cell (`gridCol`: the grid's column index). */
  onFrozenFocus(gridCol: number): void {
    if (!this.frozenLayout?.lefts.has(gridCol)) return;
    // a press restores on its click, after the grid's pointerup scroll
    if (this.pressing) return;
    afterRender(this.sheet, () => this.keepFrozenScroll());
  }
}
