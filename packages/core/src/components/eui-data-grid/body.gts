import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  euiDataGridBodyStyles,
  euiDataGridScrollBarStyles
} from '../../utils/eui/styles.generated.ts';
import { afterRender, observeResize } from '../../utils/data-grid/scheduling.ts';
import EuiDataGridBodyBase from './body-base.ts';
import EuiDataGridFooterRow from './footer-row.gts';
import EuiDataGridHeaderRow from './header-row.gts';
import EuiDataGridRow from './row.gts';

import type { EuiDataGridBodyBaseArgs } from './body-base.ts';
import type { EuiDataGridSignature } from '../eui-data-grid.gts';
import type {
  EuiDataGridFocusedCell,
  EuiDataGridScrollToItemProps,
  EuiDataGridScrollToProps
} from '../../utils/data-grid/types.ts';

// Offset for the cell actions menu when scrolling a cell below the sticky header
const ACTIONS_MENU_HEIGHT = 21;

interface Window {
  start: number;
  stop: number;
}

export interface EuiDataGridBodySignature {
  Args: EuiDataGridBodyBaseArgs & {
    hasCellPopoverBlock?: boolean;
  };
  Blocks: Pick<
    EuiDataGridSignature['Blocks'],
    | 'cell'
    | 'cellPopover'
    | 'footerCell'
    | 'controlHeaderCell'
    | 'controlCell'
    | 'controlFooterCell'
  >;
}

/** Port of react-window's `getOffsetForIndexAndAlignment` (VariableSizeGrid). */
function getOffsetForIndexAndAlignment({
  align,
  size,
  totalSize,
  offset,
  itemSize,
  scrollOffset,
  scrollbarSize
}: {
  align: NonNullable<EuiDataGridScrollToItemProps['align']>;
  size: number;
  totalSize: number;
  offset: number;
  itemSize: number;
  scrollOffset: number;
  scrollbarSize: number;
}): number {
  const maxOffset = Math.max(0, Math.min(totalSize - size, offset));
  const minOffset = Math.max(0, offset - size + scrollbarSize + itemSize);
  if (align === 'smart') {
    align =
      scrollOffset >= minOffset - size && scrollOffset <= maxOffset + size ? 'auto' : 'center';
  }
  switch (align) {
    case 'start':
      return maxOffset;
    case 'end':
      return minOffset;
    case 'center':
      return Math.round(minOffset + (maxOffset - minOffset) / 2);
    case 'auto':
    default:
      if (scrollOffset >= minOffset && scrollOffset <= maxOffset) return scrollOffset;
      if (minOffset > maxOffset) return minOffset; // the item is larger than the viewport
      if (scrollOffset < minOffset) return minOffset;
      return maxOffset;
  }
}

/** Binary search: index of the last offset `<= value`. */
function findIndex(offsets: ArrayLike<number>, count: number, value: number): number {
  let low = 0;
  let high = count - 1;
  while (low < high) {
    const mid = (low + high + 1) >> 1;
    if (offsets[mid]! <= value) low = mid;
    else high = mid - 1;
  }
  return Math.max(0, low);
}

/**
 * The virtualized grid body: a scroll container whose inner element is sized
 * to all rows/columns, a sticky header row, absolutely positioned rows and a
 * sticky footer row. Only the rows/columns intersecting the viewport (plus
 * overscan) are rendered. The rendered window is recomputed on scroll but
 * only invalidates rendering when its integer bounds change.
 */
export default class EuiDataGridBody extends EuiDataGridBodyBase<EuiDataGridBodySignature> {
  readonly isVirtualized = true;

  outerElement: HTMLElement | null = null;
  innerElement: HTMLElement | null = null;
  headerElement: HTMLElement | null = null;
  footerElement: HTMLElement | null = null;

  /* measurements -------------------------------------------------------- */
  @tracked wrapperWidth = 0;
  @tracked wrapperHeight = 0;
  @tracked outerClientWidth = 0;
  @tracked headerRowHeight = 0;
  @tracked footerRowHeight = 0;
  @tracked scrollBarHeight = 0;
  @tracked scrollBarWidth = 0;
  @tracked hasVerticalScroll = false;
  @tracked hasHorizontalScroll = false;
  /** Height when the wrapper constrains the grid (set like upstream's useFinalGridDimensions). */
  @tracked constrainedHeight: number | undefined = undefined;

  /* scrolling ----------------------------------------------------------- */
  private scrollTop = 0;
  private scrollLeft = 0;
  /** Bumped only when the rendered window must change. */
  @tracked private scrollVersion = 0;

  /* -------------------------------------------------------------------- */
  /* Column widths                                                        */
  /* -------------------------------------------------------------------- */

  get availableWidth(): number {
    return this.outerClientWidth || this.wrapperWidth;
  }

  @cached
  get columnOffsets(): number[] {
    const widths = this.columnWidthList;
    const offsets = new Array<number>(widths.length + 1);
    offsets[0] = 0;
    for (let i = 0; i < widths.length; i++) offsets[i + 1] = offsets[i]! + widths[i]!;
    return offsets;
  }

  get totalWidth(): number {
    const offsets = this.columnOffsets;
    return offsets[offsets.length - 1]!;
  }

  columnLeft(colIndex: number): number {
    return this.columnOffsets[colIndex] ?? 0;
  }

  /* -------------------------------------------------------------------- */
  /* Row heights                                                          */
  /* -------------------------------------------------------------------- */

  get visibleRowCount(): number {
    return this.grid.visibleRows.visibleRowCount;
  }

  /** Prefix sums of row heights, or null for uniform rows. */
  @cached
  get rowOffsets(): Float64Array | null {
    void this.rowHeightsVersion;
    if (this.hasUniformRowHeights) return null;
    const count = this.visibleRowCount;
    const offsets = new Float64Array(count + 1);
    for (let i = 0; i < count; i++) offsets[i + 1] = offsets[i]! + this.getRowHeight(i);
    return offsets;
  }

  rowTop(visibleRowIndex: number): number {
    const offsets = this.rowOffsets;
    return offsets ? offsets[visibleRowIndex]! : visibleRowIndex * this.defaultRowHeight;
  }

  rowHeight(visibleRowIndex: number): number {
    const offsets = this.rowOffsets;
    return offsets
      ? offsets[visibleRowIndex + 1]! - offsets[visibleRowIndex]!
      : this.defaultRowHeight;
  }

  get totalRowsHeight(): number {
    const offsets = this.rowOffsets;
    return offsets ? offsets[this.visibleRowCount]! : this.visibleRowCount * this.defaultRowHeight;
  }

  /** Index of the visible row at a vertical offset (row coordinates). */
  rowAt(offset: number): number {
    const count = this.visibleRowCount;
    if (count === 0) return 0;
    const offsets = this.rowOffsets;
    if (!offsets) return Math.min(count - 1, Math.max(0, Math.floor(offset / this.defaultRowHeight)));
    return Math.min(count - 1, findIndex(offsets, count, offset));
  }

  /* -------------------------------------------------------------------- */
  /* Grid height & width                                                  */
  /* -------------------------------------------------------------------- */

  get showHeader(): boolean {
    return this.grid.showHeader;
  }

  get headerOffset(): number {
    return this.showHeader ? this.headerRowHeight : 0;
  }

  /** Total possible height: every row of the page, header, footer and scrollbar. */
  get unconstrainedHeight(): number {
    return (
      this.totalRowsHeight +
      this.headerOffset +
      this.footerRowHeight +
      this.scrollBarHeight
    );
  }

  get finalHeight(): number {
    if (this.grid.isFullScreen) return this.wrapperHeight;
    return this.constrainedHeight || this.unconstrainedHeight;
  }

  get finalWidth(): number {
    return this.wrapperWidth;
  }

  get isMeasured(): boolean {
    return this.finalWidth > 0;
  }

  /* -------------------------------------------------------------------- */
  /* Rendered window                                                      */
  /* -------------------------------------------------------------------- */

  get overscanRowCount(): number {
    return this.grid.args.virtualizationOptions?.overscanRowCount ?? 1;
  }

  get overscanColumnCount(): number {
    return this.grid.args.virtualizationOptions?.overscanColumnCount ?? 1;
  }

  private computeRowWindow(scrollTop: number): Window & { visibleStart: number; visibleStop: number } {
    const count = this.visibleRowCount;
    if (count === 0) return { start: 0, stop: 0, visibleStart: 0, visibleStop: 0 };
    const viewport = Math.max(this.finalHeight - this.headerOffset, 0);
    const top = Math.max(0, scrollTop);
    const visibleStart = this.rowAt(top);
    let visibleStop = visibleStart;
    const bottom = top + viewport;
    while (visibleStop < count - 1 && this.rowTop(visibleStop + 1) < bottom) visibleStop++;
    const overscan = this.overscanRowCount;
    return {
      start: Math.max(0, visibleStart - overscan),
      stop: Math.min(count, visibleStop + 1 + overscan),
      visibleStart,
      visibleStop
    };
  }

  private computeColumnWindow(scrollLeft: number): Window & { visibleStart: number; visibleStop: number } {
    const count = this.grid.visibleColCount;
    if (count === 0) return { start: 0, stop: 0, visibleStart: 0, visibleStop: 0 };
    const offsets = this.columnOffsets;
    const viewport = this.outerClientWidth || this.finalWidth;
    const left = Math.max(0, scrollLeft);
    const visibleStart = Math.min(count - 1, findIndex(offsets, count, left));
    let visibleStop = visibleStart;
    while (visibleStop < count - 1 && offsets[visibleStop + 1]! < left + viewport) visibleStop++;
    const overscan = this.overscanColumnCount;
    return {
      start: Math.max(0, visibleStart - overscan),
      stop: Math.min(count, visibleStop + 1 + overscan),
      visibleStart,
      visibleStop
    };
  }

  @cached
  get rowWindow(): Window {
    void this.scrollVersion;
    const { start, stop } = this.computeRowWindow(this.scrollTop);
    return { start, stop };
  }

  @cached
  get columnWindow(): Window {
    void this.scrollVersion;
    const { start, stop } = this.computeColumnWindow(this.scrollLeft);
    return { start, stop };
  }

  @cached
  get renderedRows(): number[] {
    if (!this.isMeasured) return [];
    // like upstream, wait for the header height before positioning rows
    if (this.showHeader && this.headerRowHeight === 0) return [];
    const { start, stop } = this.rowWindow;
    const rows: number[] = [];
    for (let i = start; i < stop; i++) rows.push(i);
    return rows;
  }

  @cached
  get renderedColumns(): number[] {
    const { start, stop } = this.columnWindow;
    const columns: number[] = [];
    for (let i = start; i < stop; i++) columns.push(i);
    return columns;
  }

  /** First fully visible row (used by ArrowDown from the sticky header). */
  get visibleRowStartIndex(): number {
    return this.computeRowWindow(this.scrollTop).visibleStart;
  }

  @action
  onScroll(): void {
    const outer = this.outerElement;
    if (!outer) return;
    this.scrollTop = outer.scrollTop;
    this.scrollLeft = outer.scrollLeft;
    this.syncWindow();
    this.notifyScroll();
  }

  /** Re-render only if the integer window bounds changed. */
  private syncWindow(): void {
    const rows = this.computeRowWindow(this.scrollTop);
    const columns = this.computeColumnWindow(this.scrollLeft);
    const current = { rows: this.rowWindow, columns: this.columnWindow };
    if (
      rows.start !== current.rows.start ||
      rows.stop !== current.rows.stop ||
      columns.start !== current.columns.start ||
      columns.stop !== current.columns.stop
    ) {
      this.scrollVersion++;
    }
  }

  private notifyScroll(): void {
    const onScroll = this.grid.args.virtualizationOptions?.onScroll;
    const outer = this.outerElement;
    if (typeof onScroll !== 'function' || !outer) return;
    const { scrollTop, scrollLeft, scrollHeight, scrollWidth, clientHeight, clientWidth } =
      outer;
    const isScrollableVertical = scrollHeight > clientHeight;
    const isScrollableHorizontal = scrollWidth > clientWidth;
    const isScrolledToBlockStart = scrollTop === 0;
    const isScrolledToInlineStart = scrollLeft === 0;
    onScroll({
      scrollTop,
      scrollLeft,
      scrollHeight,
      scrollWidth,
      clientHeight,
      clientWidth,
      isScrolledToBlockStart,
      isScrolledToBlockEnd:
        isScrollableVertical &&
        !isScrolledToBlockStart &&
        scrollHeight - scrollTop <= clientHeight,
      isScrolledToInlineStart,
      isScrolledToInlineEnd:
        isScrollableHorizontal &&
        !isScrolledToInlineStart &&
        scrollWidth - scrollLeft <= clientWidth
    });
  }

  /** Reports the rendered window like react-window's `onItemsRendered`. */
  itemsRendered = modifier(
    (_element: HTMLElement, [rows, columns]: [Window, Window]) => {
      const onItemsRendered = this.grid.args.virtualizationOptions?.onItemsRendered;
      if (!onItemsRendered || !this.isMeasured) return;
      const rowWindow = this.computeRowWindow(this.scrollTop);
      const columnWindow = this.computeColumnWindow(this.scrollLeft);
      // reported after rendering, so consumers can update their own state
      afterRender(this, () => onItemsRendered({
        overscanRowStartIndex: rows.start,
        overscanRowStopIndex: Math.max(rows.start, rows.stop - 1),
        overscanColumnStartIndex: columns.start,
        overscanColumnStopIndex: Math.max(columns.start, columns.stop - 1),
        visibleRowStartIndex: rowWindow.visibleStart,
        visibleRowStopIndex: rowWindow.visibleStop,
        visibleColumnStartIndex: columnWindow.visibleStart,
        visibleColumnStopIndex: columnWindow.visibleStop
      }));
    }
  );

  /* -------------------------------------------------------------------- */
  /* Measuring                                                            */
  /* -------------------------------------------------------------------- */

  @action
  measure(): void {
    if (this.isDestroying || this.isDestroyed) return;
    const outer = this.outerElement;
    const wrapper = outer?.parentElement;
    if (!outer || !wrapper) return;
    // the height the current layout was rendered with
    const layoutUnconstrainedHeight = this.unconstrainedHeight;
    // layout sizes (offset*), unaffected by CSS transforms on ancestors
    const rect = { width: wrapper.offsetWidth, height: wrapper.offsetHeight };
    if (rect.width !== this.wrapperWidth) this.wrapperWidth = rect.width;
    if (rect.height !== this.wrapperHeight) this.wrapperHeight = rect.height;
    if (outer.clientWidth !== this.outerClientWidth && outer.clientWidth > 0)
      this.outerClientWidth = outer.clientWidth;

    const headerHeight = this.headerElement?.offsetHeight ?? 0;
    if (headerHeight !== this.headerRowHeight) this.headerRowHeight = headerHeight;
    const footerHeight = this.footerElement?.offsetHeight ?? 0;
    if (footerHeight !== this.footerRowHeight) this.footerRowHeight = footerHeight;

    const scrollBarHeight = outer.offsetHeight - outer.clientHeight;
    const scrollBarWidth = outer.offsetWidth - outer.clientWidth;
    if (scrollBarHeight !== this.scrollBarHeight) this.scrollBarHeight = scrollBarHeight;
    if (scrollBarWidth !== this.scrollBarWidth) this.scrollBarWidth = scrollBarWidth;
    const hasHorizontalScroll = outer.scrollWidth > outer.clientWidth;
    const hasVerticalScroll = outer.scrollHeight > outer.clientHeight;
    if (hasHorizontalScroll !== this.hasHorizontalScroll)
      this.hasHorizontalScroll = hasHorizontalScroll;
    if (hasVerticalScroll !== this.hasVerticalScroll) this.hasVerticalScroll = hasVerticalScroll;

    // useFinalGridDimensions: a wrapper height different from the content's
    // own height means something (height, flex parent, fullscreen) constrains it
    if (!this.grid.isFullScreen) {
      if (Math.round(rect.height) !== Math.round(layoutUnconstrainedHeight)) {
        if (this.constrainedHeight !== rect.height) this.constrainedHeight = rect.height;
      }
    }
    this.syncWindow();
  }

  setupOuter = modifier((element: HTMLElement) => {
    this.outerElement = element;
    this.scrollTop = element.scrollTop;
    this.scrollLeft = element.scrollLeft;
    const stop = observeResize(
      element.parentElement ? [element, element.parentElement] : [element],
      this.measure
    );
    afterRender(this, this.measure);
    return () => {
      stop();
      this.outerElement = null;
    };
  });

  setupInner = modifier((element: HTMLElement) => {
    this.innerElement = element;
    // horizontal scrollbars appear/disappear when the inner width changes
    const stop = observeResize([element], this.measure);
    return () => {
      stop();
      this.innerElement = null;
    };
  });

  registerHeader = modifier((element: HTMLElement) => {
    this.headerElement = element;
    const stop = observeResize([element], this.measure);
    afterRender(this, this.measure);
    return () => {
      stop();
      if (this.headerElement === element) {
        this.headerElement = null;
        afterRender(this, this.measure);
      }
    };
  });

  registerFooter = modifier((element: HTMLElement) => {
    this.footerElement = element;
    const stop = observeResize([element], this.measure);
    afterRender(this, this.measure);
    return () => {
      stop();
      if (this.footerElement === element) {
        this.footerElement = null;
        afterRender(this, this.measure);
      }
    };
  });

  /* -------------------------------------------------------------------- */
  /* Scrolling cells into view                                            */
  /* -------------------------------------------------------------------- */

  private isPointerDown = false;
  private pendingScroll = false;

  @action
  onPointerDown(): void {
    this.isPointerDown = true;
    const onPointerUp = (event: PointerEvent) => {
      this.isPointerDown = false;
      document.removeEventListener('pointerup', onPointerUp, true);
      if (!this.pendingScroll) return;
      this.pendingScroll = false;
      // only primary-button clicks; middle clicks scroll on Windows
      if (event.pointerType === 'mouse' && event.button !== 0) return;
      // skip if the interaction resulted in text being selected
      if (window.getSelection()?.type === 'Range') return;
      const focused = this.grid.focusedCell;
      if (focused) this.scrollCellIntoView({ rowIndex: focused[1], colIndex: focused[0] });
    };
    document.addEventListener('pointerup', onPointerUp, true);
  }

  onFocusedCellChange(cell: EuiDataGridFocusedCell): void {
    if (this.isPointerDown) {
      // defer the scroll decision to pointerup
      this.pendingScroll = true;
      return;
    }
    this.scrollCellIntoView({ rowIndex: cell[1], colIndex: cell[0] });
  }

  /**
   * Port of `useScrollCellIntoView`: keeps the cell fully visible, accounting
   * for the sticky header/footer and scrollbars. Positions come from the
   * row/column offsets, so cells outside the rendered window work too.
   */
  @action
  scrollCellIntoView({ rowIndex, colIndex }: { rowIndex: number; colIndex: number }): void {
    const outer = this.outerElement;
    if (!outer) return;
    if (!(this.hasVerticalScroll || this.hasHorizontalScroll)) return;

    const isStickyHeader = rowIndex === -1;
    const hasStickyFooter = this.hasFooter && !!this.grid.gridStyles.stickyFooter;
    const isStickyFooter = hasStickyFooter && rowIndex === this.visibleRowCount;
    const { scrollTop, scrollLeft, clientWidth, clientHeight } = outer;
    let adjustedScrollTop: number | undefined;
    let adjustedScrollLeft: number | undefined;

    const cellLeftPos = this.columnLeft(colIndex);
    const cellRightPos = cellLeftPos + (this.columnWidthList[colIndex] ?? 0);
    const rightWidthOutOfView = cellRightPos - (scrollLeft + clientWidth);
    if (rightWidthOutOfView > 0) adjustedScrollLeft = scrollLeft + rightWidthOutOfView;
    const leftWidthOutOfView = (adjustedScrollLeft ?? scrollLeft) - cellLeftPos;
    if (leftWidthOutOfView > 0) adjustedScrollLeft = cellLeftPos;

    if (!isStickyHeader && !isStickyFooter && rowIndex < this.visibleRowCount) {
      const headerRowHeight = this.headerOffset;
      const cellTopPos = headerRowHeight + this.rowTop(rowIndex);
      const cellBottomPos = cellTopPos + this.rowHeight(rowIndex);
      let bottomScrollBound = scrollTop + clientHeight;
      if (hasStickyFooter) bottomScrollBound -= this.footerRowHeight;
      const bottomHeightOutOfView = cellBottomPos - bottomScrollBound;
      if (bottomHeightOutOfView > 0) adjustedScrollTop = scrollTop + bottomHeightOutOfView;
      const topScrollBound = adjustedScrollTop ?? scrollTop + headerRowHeight;
      const topHeightOutOfView = topScrollBound - cellTopPos;
      if (topHeightOutOfView > 0) {
        adjustedScrollTop = Math.max(0, cellTopPos - headerRowHeight - ACTIONS_MENU_HEIGHT);
      }
    }

    if (adjustedScrollTop !== undefined || adjustedScrollLeft !== undefined) {
      outer.scrollTo({
        top: adjustedScrollTop ?? scrollTop,
        left: adjustedScrollLeft ?? scrollLeft
      });
      // render the target cell now instead of waiting for the scroll event
      this.onScroll();
    }
  }

  /* -------------------------------------------------------------------- */
  /* Layout shift compensation (`rowHeightsOptions.scrollAnchorRow`)      */
  /* -------------------------------------------------------------------- */

  /** The row layout the grid last rendered with. */
  private layoutSnapshot: {
    offsets: Float64Array | null;
    defaultHeight: number;
    count: number;
  } | null = null;

  /**
   * Port of upstream `compensateForLayoutShift`: when rows above the anchor
   * row (the first or the middle visible row) change height, scroll by the
   * anchor row's vertical shift so the content in view stays put. Upstream
   * runs this from the first cell of each row; here it runs once per row
   * layout change, comparing the anchor row's top before and after.
   */
  compensateLayoutShift = modifier(
    (element: HTMLElement, [offsets, defaultHeight]: [Float64Array | null, number]) => {
      const count = this.visibleRowCount;
      const previous = this.layoutSnapshot;
      this.layoutSnapshot = { offsets, defaultHeight, count };
      const anchor = this.rowHeightsOptions.scrollAnchorRow;
      if (!anchor || !previous || previous.count !== count || count === 0) return;
      const topOf = (snapshot: NonNullable<typeof previous>, index: number) =>
        snapshot.offsets ? snapshot.offsets[index]! : index * snapshot.defaultHeight;
      // the visible rows of the previous layout at the current scroll position
      const scrollTop = element.scrollTop;
      const viewportBottom = scrollTop + Math.max(this.finalHeight - this.headerOffset, 0);
      let start = 0;
      while (start < count - 1 && topOf(previous, start + 1) <= scrollTop) start++;
      let stop = start;
      while (stop < count - 1 && topOf(previous, stop + 1) < viewportBottom) stop++;
      // upstream compares the center offset with the row index itself, which
      // only finds the center row when scrolled to the top; use the real center row
      const anchorRow = anchor === 'start' ? start : start + Math.floor((stop - start) / 2);
      const shift = topOf(this.layoutSnapshot, anchorRow) - topOf(previous, anchorRow);
      if (!shift || !Number.isFinite(shift)) return;
      element.scrollTop = scrollTop + shift;
      afterRender(this, this.onScroll);
    }
  );

  /* -------------------------------------------------------------------- */
  /* Imperative scrolling (react-window's grid API)                       */
  /* -------------------------------------------------------------------- */

  /** react-window `scrollTo`: offsets in px; a missing offset is kept. */
  @action
  scrollTo({ scrollLeft, scrollTop }: EuiDataGridScrollToProps = {}): void {
    const outer = this.outerElement;
    if (!outer) return;
    outer.scrollTo({
      left: scrollLeft ?? outer.scrollLeft,
      top: scrollTop ?? outer.scrollTop
    });
    this.onScroll();
  }

  /** react-window `scrollToItem`: brings a row and/or column into view. */
  @action
  scrollToItem({ align = 'auto', columnIndex, rowIndex }: EuiDataGridScrollToItemProps = {}): void {
    const outer = this.outerElement;
    if (!outer) return;
    const columnCount = this.grid.visibleColCount;
    const rowCount = this.visibleRowCount;
    const height = this.finalHeight;
    const width = this.finalWidth;
    const totalHeight = this.totalRowsHeight;
    const totalWidth = this.totalWidth;
    // react-window adds the scrollbar of the other axis to the item's minimum offset
    const horizontalScrollbarSize = totalWidth > width ? this.scrollBarHeight : 0;
    const verticalScrollbarSize = totalHeight > height ? this.scrollBarWidth : 0;
    let scrollLeft: number | undefined;
    let scrollTop: number | undefined;
    if (columnIndex !== undefined && columnCount > 0) {
      const index = Math.max(0, Math.min(columnIndex, columnCount - 1));
      scrollLeft = getOffsetForIndexAndAlignment({
        align,
        size: width,
        totalSize: totalWidth,
        offset: this.columnLeft(index),
        itemSize: this.columnWidthList[index] ?? 0,
        scrollOffset: outer.scrollLeft,
        scrollbarSize: verticalScrollbarSize
      });
    }
    if (rowIndex !== undefined && rowCount > 0) {
      const index = Math.max(0, Math.min(rowIndex, rowCount - 1));
      scrollTop = getOffsetForIndexAndAlignment({
        align,
        size: height,
        totalSize: totalHeight,
        offset: this.rowTop(index),
        itemSize: this.rowHeight(index),
        scrollOffset: outer.scrollTop,
        scrollbarSize: horizontalScrollbarSize
      });
    }
    this.scrollTo({ scrollLeft, scrollTop });
  }

  /* -------------------------------------------------------------------- */
  /* Styles                                                               */
  /* -------------------------------------------------------------------- */

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    return {
      context,
      body: useEuiBorealisStyles(context, euiDataGridBodyStyles),
      scroll: useEuiBorealisStyles(context, euiDataGridScrollBarStyles)
    };
  }

  @cached
  get outerClass(): string {
    const { context, body } = this.styles;
    return `euiDataGrid__virtualized ${euiClass(context, body.euiDataGridBody, body.virtualized)}`;
  }

  get outerStyle() {
    const height = this.finalHeight;
    const width = this.finalWidth;
    return htmlSafe(
      `position:relative;height:${height}px;width:${width ? `${width}px` : '100%'};overflow:auto;will-change:transform;direction:ltr`
    );
  }

  get innerStyle() {
    return htmlSafe(
      `position:relative;height:${this.totalRowsHeight + this.headerOffset}px;width:${this.totalWidth}px`
    );
  }

  get showScrollOverlay(): boolean {
    if (!this.hasHorizontalScroll && !this.hasVerticalScroll) return false;
    return this.grid.gridStyles.border !== 'none';
  }

  @cached
  get scrollOverlayClasses() {
    const { context, scroll } = this.styles;
    return {
      overlay: `euiDataGrid__scrollOverlay ${euiClass(context, scroll.euiDataGrid__scrollOverlay)}`,
      bottom: `euiDataGrid__scrollBarOverlayBottom ${euiClass(context, scroll.euiDataGrid__scrollBarOverlayBottom)}`,
      right: `euiDataGrid__scrollBarOverlayRight ${euiClass(context, scroll.euiDataGrid__scrollBarOverlayRight)}`
    };
  }

  get scrollBarBottomStyle() {
    return htmlSafe(`inset-block-end:${this.scrollBarHeight}px`);
  }

  get scrollBarRightStyle() {
    return htmlSafe(
      `inset-block-start:0;inset-block-end:${this.scrollBarHeight}px;inset-inline-end:${this.scrollBarWidth}px`
    );
  }

  <template>
    <div
      class={{this.outerClass}}
      style={{this.outerStyle}}
      {{on "scroll" this.onScroll}}
      {{on "pointerdown" this.onPointerDown}}
      {{this.setupOuter}}
      {{this.itemsRendered this.rowWindow this.columnWindow}}
      {{this.compensateLayoutShift this.rowOffsets this.defaultRowHeight}}
    >
      {{#if this.isMeasured}}
        <div style={{this.innerStyle}} {{this.setupInner}}>
          {{#if this.showHeader}}
            <EuiDataGridHeaderRow @grid={{@grid}} @body={{this}} {{this.registerHeader}}>
              <:controlHeaderCell as |cell|>{{yield cell to="controlHeaderCell"}}</:controlHeaderCell>
            </EuiDataGridHeaderRow>
          {{/if}}
          {{#each this.renderedRows key="@identity" as |visibleRowIndex|}}
            <EuiDataGridRow
              @grid={{@grid}}
              @body={{this}}
              @visibleRowIndex={{visibleRowIndex}}
              @hasCellPopoverBlock={{@hasCellPopoverBlock}}
            >
              <:cell as |cell|>{{yield cell to="cell"}}</:cell>
              <:cellPopover as |popover|>{{yield popover to="cellPopover"}}</:cellPopover>
              <:controlCell as |cell|>{{yield cell to="controlCell"}}</:controlCell>
            </EuiDataGridRow>
          {{/each}}
        </div>
        {{#if this.hasFooter}}
          <EuiDataGridFooterRow
            @grid={{@grid}}
            @body={{this}}
            @hasCellPopoverBlock={{@hasCellPopoverBlock}}
            {{this.registerFooter}}
          >
            <:footerCell as |cell|>{{yield cell to="footerCell"}}</:footerCell>
            <:cellPopover as |popover|>{{yield popover to="cellPopover"}}</:cellPopover>
            <:controlFooterCell as |cell|>{{yield cell to="controlFooterCell"}}</:controlFooterCell>
          </EuiDataGridFooterRow>
        {{/if}}
      {{/if}}
    </div>
    {{#if this.showScrollOverlay}}
      <div class={{this.scrollOverlayClasses.overlay}} role="presentation">
        {{#if this.scrollBarHeight}}
          <div
            class={{this.scrollOverlayClasses.bottom}}
            style={{this.scrollBarBottomStyle}}
          ></div>
        {{/if}}
        {{#if this.scrollBarWidth}}
          <div
            class={{this.scrollOverlayClasses.right}}
            style={{this.scrollBarRightStyle}}
          ></div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
