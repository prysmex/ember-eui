import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import {
  DEFAULT_ROW_HEIGHT,
  RowHeightUtils
} from '../../utils/data-grid/row-heights.ts';

import type Owner from '@ember/owner';
import type EuiDataGrid from '../eui-data-grid.gts';
import type {
  EuiDataGridColumn,
  EuiDataGridFocusedCell,
  EuiDataGridRowHeightsOptions,
  EuiDataGridScrollToItemProps,
  EuiDataGridScrollToProps
} from '../../utils/data-grid/types.ts';

export const DEFAULT_COLUMN_WIDTH = 100;

export interface EuiDataGridBodyBaseArgs {
  grid: EuiDataGrid;
  hasFooterBlock?: boolean;
}

const doesColumnHaveAnInitialWidth = (column: EuiDataGridColumn) =>
  column.initialWidth != null;

/**
 * State shared by the virtualized body and the custom body renderer
 * (`@renderCustomGridBody`): column widths (`useColumnWidths` /
 * `useDefaultColumnWidth` upstream) and row heights (`useRowHeightUtils` /
 * `useDefaultRowHeight`). Header, row and footer cells read these.
 */
export default abstract class EuiDataGridBodyBase<
  S extends { Args: EuiDataGridBodyBaseArgs }
> extends Component<S> {
  /** Whether rows and cells are absolutely positioned (virtualized). */
  abstract readonly isVirtualized: boolean;

  /** Width the default column width fills. */
  abstract get availableWidth(): number;

  constructor(owner: Owner, args: S['Args']) {
    super(owner, args);
    args.grid.body = this;
  }

  willDestroy(): void {
    super.willDestroy();
    if (this.args.grid.body === this) this.args.grid.body = null;
    clearTimeout(this.resetTimer);
  }

  get grid(): EuiDataGrid {
    return this.args.grid;
  }

  get hasFooter(): boolean {
    return !!this.grid.args.renderFooterCellValue || !!this.args.hasFooterBlock;
  }

  /* -------------------------------------------------------------------- */
  /* Column widths                                                        */
  /* -------------------------------------------------------------------- */

  // user resizes, reset whenever the visible columns change (like upstream)
  @tracked private columnWidthsState: {
    columns: EuiDataGridColumn[];
    widths: Record<string, number>;
  } | null = null;

  get columnWidths(): Record<string, number> {
    const columns = this.grid.columns;
    const state = this.columnWidthsState;
    if (state && state.columns === columns) return state.widths;
    return this.initialColumnWidths;
  }

  @cached
  get initialColumnWidths(): Record<string, number> {
    const widths: Record<string, number> = {};
    for (const column of this.grid.columns.filter(doesColumnHaveAnInitialWidth)) {
      widths[column.id] = column.initialWidth!;
    }
    return widths;
  }

  @action
  setColumnWidth(columnId: string, width: number): void {
    this.columnWidthsState = {
      columns: this.grid.columns,
      widths: { ...this.columnWidths, [columnId]: width }
    };
    this.grid.args.onColumnResize?.({ columnId, width });
  }

  /** Default width for columns without `initialWidth`, filling the container. */
  get defaultColumnWidth(): number | null {
    const gridWidth = this.availableWidth;
    if (gridWidth === 0) return null; // we can't tell what size to compute yet
    const { leadingControlColumns, trailingControlColumns, columns } = this.grid;
    const controlColumnWidths = [
      ...leadingControlColumns,
      ...trailingControlColumns
    ].reduce((claimed, column) => claimed + column.width, 0);
    const columnsWithWidths = columns.filter(doesColumnHaveAnInitialWidth);
    const definedColumnsWidth = columnsWithWidths.reduce(
      (claimed, column) => claimed + column.initialWidth!,
      0
    );
    const widthToFill = gridWidth - controlColumnWidths - definedColumnsWidth;
    const unsizedColumnCount = columns.length - columnsWithWidths.length;
    if (unsizedColumnCount === 0) return DEFAULT_COLUMN_WIDTH;
    return Math.max(widthToFill / unsizedColumnCount, DEFAULT_COLUMN_WIDTH);
  }

  /** Width of a data column by id (undefined until the grid is measured). */
  widthForColumn(columnId: string): number | undefined {
    return this.columnWidths[columnId] || this.defaultColumnWidth || undefined;
  }

  /** Every visible column's width, by visible column index. */
  @cached
  get columnWidthList(): number[] {
    const { leadingControlColumns, trailingControlColumns, columns } = this.grid;
    const widths = this.columnWidths;
    const fallback = this.defaultColumnWidth || DEFAULT_COLUMN_WIDTH;
    return [
      ...leadingControlColumns.map((column) => column.width),
      ...columns.map((column) => widths[column.id] || fallback),
      ...trailingControlColumns.map((column) => column.width)
    ];
  }

  /* -------------------------------------------------------------------- */
  /* Row heights                                                          */
  /* -------------------------------------------------------------------- */

  @tracked protected rowHeightsVersion = 0;
  private resetTimer: ReturnType<typeof setTimeout> | undefined;

  readonly rowHeightUtils = new RowHeightUtils(() => {
    // batch measured height changes into one offsets recomputation
    clearTimeout(this.resetTimer);
    this.resetTimer = setTimeout(() => {
      if (!this.isDestroying) this.onRowHeightsChange();
    }, 0);
  });

  /** Measured (auto/line count) row heights changed. */
  protected onRowHeightsChange(): void {
    this.rowHeightsVersion++;
  }

  /** `minRowHeight` upstream: measured single-line height of a cell. */
  @tracked minRowHeight = DEFAULT_ROW_HEIGHT;

  @action
  setMinRowHeight(height: number): void {
    if (this.minRowHeight !== height) this.minRowHeight = height;
  }

  get rowHeightsOptions(): EuiDataGridRowHeightsOptions {
    return this.grid.rowHeightsOptions;
  }

  get defaultRowHeight(): number {
    const options = this.rowHeightsOptions;
    return options?.defaultHeight
      ? this.rowHeightUtils.getCalculatedHeight(options.defaultHeight, this.minRowHeight)
      : this.minRowHeight;
  }

  /** Whether every row has the default height (no per-row or measured heights). */
  get hasUniformRowHeights(): boolean {
    const options = this.rowHeightsOptions;
    if (options.rowHeights && Object.keys(options.rowHeights).length > 0) return false;
    if (options.defaultHeight === 'auto') return false;
    if (this.rowHeightUtils.isAutoBelowLineCount(options, options.defaultHeight))
      return false;
    return true;
  }

  /** Height of a visible (page-relative) row. */
  getRowHeight(visibleRowIndex: number): number {
    const defaultRowHeight = this.defaultRowHeight;
    if (this.hasUniformRowHeights) return defaultRowHeight;
    const options = this.rowHeightsOptions;
    const rowIndex = this.grid.getCorrectRowIndex(visibleRowIndex);
    const option = this.rowHeightUtils.getRowHeightOption(rowIndex, options);
    let rowHeight: number | undefined;
    if (option) {
      rowHeight = this.rowHeightUtils.getCalculatedHeight(
        option,
        this.minRowHeight,
        rowIndex,
        options
      );
    }
    return rowHeight || defaultRowHeight;
  }

  /** Height a row renders with. */
  rowHeight(visibleRowIndex: number): number {
    void this.rowHeightsVersion;
    return this.getRowHeight(visibleRowIndex);
  }

  /** Left offset of a column (positioned cells only). */
  columnLeft(colIndex: number): number {
    void colIndex;
    return 0;
  }

  /* -------------------------------------------------------------------- */
  /* Scrolling (no-ops unless virtualized)                                */
  /* -------------------------------------------------------------------- */

  /** First fully visible row (used by ArrowDown from the sticky header). */
  get visibleRowStartIndex(): number {
    return 0;
  }

  onFocusedCellChange(cell: EuiDataGridFocusedCell): void {
    void cell;
  }

  scrollCellIntoView(cell: { rowIndex: number; colIndex: number }): void {
    void cell;
  }

  scrollTo?(params?: EuiDataGridScrollToProps): void;

  scrollToItem?(params?: EuiDataGridScrollToItemProps): void;
}
