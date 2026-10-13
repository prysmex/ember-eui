import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';

import { focusTrap } from 'ember-focus-trap';
import { focusTrapFactory } from '../-private/focus-trap-registry.ts';
import { modifier } from 'ember-modifier';
import { or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiDataGridStyles } from '../utils/eui/styles.generated.ts';
import { euiDataGridFullScreenStyles } from '../utils/eui/data-grid.ts';
import {
  copyFocusedDataGridCell,
  handleGridKeyDown,
  preventTabbing
} from '../utils/data-grid/focus.ts';
import {
  detectSchema,
  mergeSchema,
  schemaDetectors as providedSchemaDetectors
} from '../utils/data-grid/schema.ts';
import { computeSortedRowMap } from '../utils/data-grid/sorting.ts';
import { afterRender, observeResize } from '../utils/data-grid/scheduling.ts';
import * as keys from '../utils/keys.ts';
import EuiDataGridBody from './eui-data-grid/body.gts';
import EuiDataGridCopyMarker from './eui-data-grid/copy-marker.gts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';
import { onTabularCopy } from '../utils/data-grid/tabular-copy.ts';
import { euiTablePaginationDefaults } from '../-private/table-pagination-defaults.ts';
import EuiDataGridCustomBody from './eui-data-grid/custom-body.gts';
import type EuiDataGridBodyBase from './eui-data-grid/body-base.ts';
import EuiDataGridInMemoryRenderer from './eui-data-grid/in-memory-renderer.gts';
import EuiDataGridPagination, {
  shouldRenderPagination
} from './eui-data-grid/pagination.gts';
import EuiDataGridToolbar from './eui-data-grid/toolbar.gts';
// ember-eui extension (row-tree): row tree state and hooks
import EuiDataGridRowModel from './eui-data-grid/row-model.ts';
import { clampRowTreePageIndex } from './eui-data-grid/row-tree-hooks.ts';

import type Owner from '@ember/owner';
import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridCellValueSignature,
  EuiDataGridColumn,
  EuiDataGridColumnVisibility,
  EuiDataGridControlColumn,
  EuiDataGridCustomToolbarProps,
  EuiDataGridFocusedCell,
  EuiDataGridGrouping,
  EuiDataGridInMemory,
  EuiDataGridInMemoryValues,
  EuiDataGridCellLocationProps,
  EuiDataGridPaginationProps,
  EuiDataGridRefProps,
  EuiDataGridRowHeightsOptions,
  EuiDataGridRowTree,
  EuiDataGridRowTreeRowInfo,
  EuiDataGridSchema,
  EuiDataGridSchemaDetector,
  EuiDataGridSorting,
  EuiDataGridStyle,
  EuiDataGridToolBarVisibilityOptions,
  EuiDataGridVirtualizationOptions
} from '../utils/data-grid/types.ts';
import type { ComponentLike } from '@glint/template';
import type { EuiDataGridCustomBodyProps } from './eui-data-grid/custom-body.gts';
import type { EuiDataGridDefaultCellPopoverSignature } from './eui-data-grid/default-cell-popover.gts';

export type * from '../utils/data-grid/types.ts';
export type {
  EuiDataGridCustomBodyCellSignature,
  EuiDataGridCustomBodyProps,
  EuiDataGridCustomFooterRowSignature,
  EuiDataGridSetCustomGridBodyProps
} from './eui-data-grid/custom-body.gts';

/** Upstream `startingStyles` (display_selector.tsx). */
export const startingStyles: Required<
  Pick<
    EuiDataGridStyle,
    | 'cellPadding'
    | 'fontSize'
    | 'border'
    | 'stripes'
    | 'rowHover'
    | 'header'
    | 'footer'
    | 'stickyFooter'
  >
> = {
  cellPadding: 'm',
  fontSize: 'm',
  border: 'all',
  stripes: false,
  rowHover: 'highlight',
  header: 'shade',
  footer: 'overline',
  stickyFooter: true
};

const fontSizesToClassMap = {
  s: 'euiDataGrid--fontSizeSmall',
  m: '',
  l: 'euiDataGrid--fontSizeLarge'
};
const headerToClassMap = {
  shade: 'euiDataGrid--headerShade',
  underline: 'euiDataGrid--headerUnderline'
};
const footerToClassMap = {
  shade: 'euiDataGrid--footerShade',
  overline: 'euiDataGrid--footerOverline',
  striped: ''
};
const rowHoverToClassMap = {
  highlight: 'euiDataGrid--rowHoverHighlight',
  none: ''
};
const bordersToClassMap = {
  all: 'euiDataGrid--bordersAll',
  horizontal: 'euiDataGrid--bordersHorizontal',
  none: 'euiDataGrid--bordersNone'
};
const cellPaddingsToClassMap = {
  s: 'euiDataGrid--paddingSmall',
  m: '',
  l: 'euiDataGrid--paddingLarge'
};

/**
 * Upstream relies on the global reset's `box-sizing: border-box` for cell
 * layout (padded contents fill their cells); scoped here with zero
 * specificity so upstream rules still win.
 */
const BOX_SIZING_RESET = {
  '*:where(&)': { boxSizing: 'border-box' },
  '*:where(& *)': { boxSizing: 'border-box' },
  '*:where(& *)::before': { boxSizing: 'border-box' },
  '*:where(& *)::after': { boxSizing: 'border-box' }
} as const;

const GRID_IS_FULLSCREEN_CLASSNAME = 'euiDataGrid__restrictBody';
const EMPTY_CONTROL_COLUMNS: EuiDataGridControlColumn[] = [];

type CellCallback = (isFocused: boolean, preventScroll?: boolean) => void;

export interface EuiDataGridCellLocation {
  rowIndex: number;
  colIndex: number;
}

/** Popover options a custom popover renderer may set with `setCellPopoverProps`. */
export interface EuiDataGridCellPopoverProps {
  panelClassName?: string;
  zIndex?: number;
  [key: string]: unknown;
}

/** Arguments of `@renderCellPopover` / the `<:cellPopover>` block. */
export interface EuiDataGridCellPopoverElementProps {
  rowIndex: number;
  colIndex: number;
  columnId: string;
  schema?: string | null;
  cellContentsElement: HTMLElement | null;
  setCellPopoverProps: (props: Record<string, unknown>) => void;
  /** The column's cell actions, as rendered in the default popover footer. */
  cellActions: ComponentLike;
  /**
   * The standard popover display (`EuiText` around its block, or the cell's
   * JSON in a code block for the `json` schema, then the cell actions), to
   * fall back to it for some columns: `<@DefaultCellPopover>{{yield}}</@DefaultCellPopover>`.
   */
  DefaultCellPopover: ComponentLike<EuiDataGridDefaultCellPopoverSignature>;
  // ember-eui extension (row-tree): the popover's row object
  /** The row object, with `@rowTree` or `@grouping.rows` (Ember EUI extension). */
  row?: any;
  // ember-eui extension (row-tree): the popover's row tree state
  /** The row's tree state, with `@rowTree` or `@grouping` (Ember EUI extension). */
  rowTree?: EuiDataGridRowTreeRowInfo;
}

export interface EuiDataGridSignature {
  Element: HTMLDivElement;
  Args: {
    /** Column definitions (`id`, `displayAsText`, `schema`, `initialWidth`, `actions`, `cellActions`, …). */
    columns: EuiDataGridColumn[];
    /**
     * Controlled column order/visibility. Optional in Ember: without it the
     * grid keeps its own state, starting with every column visible.
     */
    columnVisibility?: EuiDataGridColumnVisibility;
    // ember-eui extension (row-tree): optional with @rowTree / @grouping.rows
    /** Number of rows in the data (not needed with `@rowTree` or `@grouping.rows`). */
    rowCount?: number;
    // ember-eui extension (row-tree): @rowTree and @grouping args
    /**
     * Ember EUI extension: nested rows. The rows array (nested through each
     * row's `children`, or flat with `parentId`), or options
     * `{ rows, getChildren, getParentId, getRowId, hasChildren,
     * expandedRowIds, defaultExpandedRowIds, onExpandedChange,
     * toggleColumnId }`.
     */
    rowTree?: EuiDataGridRowTree;
    /**
     * Ember EUI extension: groups rows by column values
     * (`{ groupBy, getValue, rows, expandedGroupIds, defaultExpandedGroupIds,
     * onExpandedChange, renderGroupCell, toggleColumnId }`).
     */
    grouping?: EuiDataGridGrouping;
    /**
     * Component rendering a cell's value; receives `@rowIndex`, `@colIndex`,
     * `@columnId`, `@isDetails`, `@isExpanded`, `@isExpandable`,
     * `@setCellProps`, `@schema`, `@cellContext` and (with `@rowTree` or
     * `@grouping.rows`) `@row`. Or use the `<:cell>` block.
     */
    renderCellValue?: ComponentLike<EuiDataGridCellValueSignature>;
    /** Extra data passed to every cell renderer as `@cellContext`. */
    cellContext?: Record<string, unknown>;
    /**
     * Component rendering the expansion popover (its default block renders
     * the cell value with `@isDetails`); or use the `<:cellPopover>` block.
     */
    renderCellPopover?: ComponentLike<{
      Args: EuiDataGridCellPopoverElementProps;
      Blocks: { default: [] };
    }>;
    /** Component rendering footer cells; or use the `<:footerCell>` block. */
    renderFooterCellValue?: ComponentLike<EuiDataGridCellValueSignature>;
    /**
     * Escape hatch replacing the virtualized body: a component receiving
     * `@Cell`, `@visibleColumns`, `@visibleRowData`, `@setCustomGridBodyProps`,
     * `@gridWidth`, `@headerRow` and `@footerRow`; or use the
     * `<:customGridBody>` block. Give cell content with `@renderCellValue`
     * or the `Cell`'s own block.
     */
    renderCustomGridBody?: ComponentLike<{ Args: EuiDataGridCustomBodyProps }>;
    /**
     * Custom toolbar layout: a component receiving the toolbar controls
     * (`@hasRoomForGridControls`, `@columnControl`, `@columnSortingControl`,
     * `@keyboardShortcutsControl`, `@displayControl`, `@fullScreenControl`,
     * `@additionalControls`); or use the `<:customToolbar>` block.
     */
    renderCustomToolbar?: ComponentLike<{ Args: EuiDataGridCustomToolbarProps }>;
    /** Columns before the data columns (e.g. row selection). */
    leadingControlColumns?: EuiDataGridControlColumn[];
    /** Columns after the data columns (e.g. row actions). */
    trailingControlColumns?: EuiDataGridControlColumn[];
    /** Extra schema detectors, appended to the defaults. */
    schemaDetectors?: EuiDataGridSchemaDetector[];
    /** Borders, header/footer styles, stripes, row hover, density. */
    gridStyle?: EuiDataGridStyle;
    /** Default and per-row heights (`'auto'`, a number, `{ lineCount }` or `{ height }`). */
    rowHeightsOptions?: EuiDataGridRowHeightsOptions;
    /** `false` hides the toolbar, or an object toggling each control. Defaults to `true`. */
    toolbarVisibility?: boolean | EuiDataGridToolBarVisibilityOptions;
    /** `false` hides the header row. Defaults to `true`. */
    headerVisibility?: boolean;
    /** Pagination state and callbacks; rendered with `EuiTablePagination`. */
    pagination?: EuiDataGridPaginationProps;
    /** Sorted columns and `onSort`. */
    sorting?: EuiDataGridSorting;
    /** Let the grid read rendered values to detect schemas and sort in memory. */
    inMemory?: EuiDataGridInMemory;
    /** Called after a column is resized. */
    onColumnResize?: (event: { columnId: string; width: number }) => void;
    /** Below this width only the right toolbar controls show. Defaults to 479. */
    minSizeForControls?: number;
    /** Grid height (CSS length or px number). Without it the grid grows with its rows. */
    height?: string | number;
    /** Grid width (CSS length or px number). */
    width?: string | number;
    /** Overscan counts and render/scroll callbacks of the virtualized body. */
    virtualizationOptions?: EuiDataGridVirtualizationOptions;
    /** Called when fullscreen mode is entered or left. */
    onFullScreenChange?: (isFullScreen: boolean) => void;
    /**
     * Called after render with the grid's imperative API (upstream's `ref`):
     * `setIsFullScreen`, `setFocusedCell`, `openCellPopover`,
     * `closeCellPopover`, `scrollTo` and `scrollToItem`.
     */
    registerApi?: (api: EuiDataGridRefProps) => void;
    /** Accessible name of the grid (same as the `aria-label` attribute). */
    ariaLabel?: string;
    /** Id(s) labelling the grid (same as the `aria-labelledby` attribute). */
    ariaLabelledBy?: string;
    /** Extra styles composed last into the grid class. */
    css?: EuiCss;
  };
  Blocks: {
    /** Cell content when `@renderCellValue` is not given. */
    cell: [EuiDataGridCellValueElementProps];
    /** Expansion popover content when `@renderCellPopover` is not given. */
    cellPopover: [EuiDataGridCellPopoverElementProps];
    /** Footer cell content when `@renderFooterCellValue` is not given. */
    footerCell: [EuiDataGridCellValueElementProps];
    /** Header of a control column without `headerCellRender`. */
    controlHeaderCell: [{ columnId: string }];
    /** Body cell of a control column without `rowCellRender`. */
    controlCell: [EuiDataGridCellValueElementProps];
    /** Footer cell of a control column without `footerCellRender`. */
    controlFooterCell: [EuiDataGridCellValueElementProps];
    /** Toolbar controls before the column/sort controls. */
    leftControlsPrepend: [];
    /** Toolbar controls after the column/sort controls. */
    leftControlsAppend: [];
    /** Toolbar controls before the right icon buttons. */
    rightControls: [];
    /** Custom toolbar (like `@renderCustomToolbar`), yielding the toolbar controls. */
    customToolbar: [EuiDataGridCustomToolbarProps];
    /** Custom grid body (like `@renderCustomGridBody`). */
    customGridBody: [EuiDataGridCustomBodyProps];
  };
}

function stableKey(value: unknown): string {
  return JSON.stringify(value, (_key, v) =>
    typeof v === 'function' ? undefined : v
  );
}

/**
 * Data grid with virtualized rows and columns, keyboard navigation, cell
 * expansion, sorting, column management, display options and pagination.
 * Port of EUI 123.1.0 `EuiDataGrid`.
 */
export default class EuiDataGrid extends Component<EuiDataGridSignature> {
  @service declare euiI18n: EuiI18n;

  readonly gridId = `euiDataGrid-${guidFor(this)}`;
  readonly interactiveCellId = `${this.gridId}-interactive`;
  readonly ariaLabelledById = `${this.gridId}-labelledby`;

  /** The grid body; registers itself to scroll focused cells into view. */
  body: EuiDataGridBodyBase<any> | null = null;
  contentElement: HTMLElement | null = null;

  /**
   * Toolbar width, kept by the root's resize observer. Only the toolbar
   * consumes it (to hide the left controls on narrow grids).
   */
  @tracked gridWidth = 0;
  @tracked isFullScreen = false;

  // `aria-label`/`aria-labelledby` attributes are moved to the role=grid element
  @tracked attrAriaLabel: string | null = null;
  @tracked attrAriaLabelledBy: string | null = null;

  /* ---------------------------------------------------------------------- */
  /* Columns                                                                */
  /* ---------------------------------------------------------------------- */

  get leadingControlColumns(): EuiDataGridControlColumn[] {
    return this.args.leadingControlColumns ?? EMPTY_CONTROL_COLUMNS;
  }

  get trailingControlColumns(): EuiDataGridControlColumn[] {
    return this.args.trailingControlColumns ?? EMPTY_CONTROL_COLUMNS;
  }

  @cached
  get displayValues(): Record<string, string> {
    const values: Record<string, string> = {};
    for (const column of this.args.columns) {
      if (!values[column.id]) values[column.id] = column.displayAsText || column.id;
    }
    return values;
  }

  @tracked private internalVisibleColumns: string[] | null = null;

  get visibleColumnIds(): string[] {
    return (
      this.args.columnVisibility?.visibleColumns ??
      this.internalVisibleColumns ??
      this.args.columns.map(({ id }) => id)
    );
  }

  @action
  setVisibleColumns(columnIds: string[]): void {
    if (this.args.columnVisibility) {
      this.args.columnVisibility.setVisibleColumns(columnIds);
    } else {
      this.internalVisibleColumns = columnIds;
    }
  }

  // Column order shown in the column selector (`useDependentState` upstream):
  // re-derived whenever a new `@columns` array is passed.
  @tracked private sortedColumnsState: {
    columns: EuiDataGridColumn[];
    ids: string[];
  } | null = null;

  @cached
  get initialSortedColumns(): string[] {
    const availableColumnIdsSet = new Set(this.args.columns.map(({ id }) => id));
    const validVisibleColumns = this.visibleColumnIds.filter((id) =>
      availableColumnIdsSet.has(id)
    );
    const visibleSet = new Set(validVisibleColumns);
    const result: string[] = [];
    let visibleIndex = 0;
    for (const columnId of availableColumnIdsSet) {
      if (visibleSet.has(columnId)) {
        if (visibleIndex < validVisibleColumns.length) {
          result.push(validVisibleColumns[visibleIndex++]!);
        }
      } else {
        result.push(columnId);
      }
    }
    return result;
  }

  get sortedColumns(): string[] {
    const state = this.sortedColumnsState;
    if (state && state.columns === this.args.columns) return state.ids;
    return this.initialSortedColumns;
  }

  @action
  setSortedColumns(nextColumns: string[]): void {
    this.sortedColumnsState = { columns: this.args.columns, ids: nextColumns };
    const visible = new Set(this.visibleColumnIds);
    this.setVisibleColumns(nextColumns.filter((id) => visible.has(id)));
  }

  /** Move a column to another column's position (header column actions). */
  @action
  switchColumnPos(fromColId: string, toColId: string): void {
    const sorted = this.sortedColumns;
    const moveFromIdx = sorted.indexOf(fromColId);
    const moveToIdx = sorted.indexOf(toColId);
    if (moveFromIdx === -1 || moveToIdx === -1) return;
    const next = [...sorted];
    next.splice(moveFromIdx, 1);
    next.splice(moveToIdx, 0, fromColId);
    this.setSortedColumns(next);
  }

  /** The visible data columns, in display order. */
  @cached
  get columns(): EuiDataGridColumn[] {
    const byId = new Map(this.args.columns.map((column) => [column.id, column]));
    const columns: EuiDataGridColumn[] = [];
    for (const id of this.visibleColumnIds) {
      const column = byId.get(id);
      if (column) columns.push(column);
    }
    return columns;
  }

  get visibleColCount(): number {
    return (
      this.columns.length +
      this.leadingControlColumns.length +
      this.trailingControlColumns.length
    );
  }

  /* ---------------------------------------------------------------------- */
  /* Rows & pagination                                                      */
  /* ---------------------------------------------------------------------- */

  @cached
  get pagination():
    | (EuiDataGridPaginationProps & { pageSize: number; pageSizeOptions: number[] })
    | undefined {
    const pagination = this.args.pagination;
    if (!pagination) return undefined;
    // upstream `useEuiTablePaginationDefaults()` (with the app's `componentDefaults`)
    const defaults = euiTablePaginationDefaults(this);
    // read each field: consumers often pass objects with tracked accessors
    return {
      pageIndex: pagination.pageIndex,
      pageSize: pagination.pageSize ?? defaults.itemsPerPage,
      pageSizeOptions: pagination.pageSizeOptions ?? defaults.itemsPerPageOptions,
      onChangePage: pagination.onChangePage,
      onChangeItemsPerPage: pagination.onChangeItemsPerPage
    };
  }

  /** `pagination` where the template already checked it is defined. */
  get definedPagination() {
    return this.pagination!;
  }

  // ember-eui extension (row-tree): tree state; `rowModel` is null without
  // @rowTree/@grouping, so the grid works exactly as upstream
  readonly rowTreeModel = new EuiDataGridRowModel(this);

  get rowModel(): EuiDataGridRowModel | null {
    return this.rowTreeModel.isActive ? this.rowTreeModel : null;
  }

  // ember-eui extension (row-tree): rows shown: `@rowCount`, or the visible tree rows
  get rowCount(): number {
    return this.rowModel?.visibleRows.length ?? this.args.rowCount ?? 0;
  }

  // ember-eui extension (row-tree): data rows (all tree levels)
  get dataRowCount(): number {
    return this.rowModel?.dataRowCount ?? this.args.rowCount ?? 0;
  }

  get showPagination(): boolean {
    const pagination = this.pagination;
    // ember-eui extension (row-tree): visible rows instead of @rowCount
    return !!pagination && shouldRenderPagination(this.rowCount, pagination);
  }

  @cached
  get visibleRows(): { startRow: number; endRow: number; visibleRowCount: number } {
    const pagination = this.pagination;
    const rowCount = this.rowCount; // ember-eui extension (row-tree): visible rows
    const startRow =
      pagination && pagination.pageSize > 0
        ? pagination.pageIndex * pagination.pageSize
        : 0;
    let endRow =
      pagination && pagination.pageSize > 0
        ? (pagination.pageIndex + 1) * pagination.pageSize
        : rowCount;
    endRow = Math.min(endRow, rowCount);
    return { startRow, endRow, visibleRowCount: Math.max(0, endRow - startRow) };
  }

  /* ---------------------------------------------------------------------- */
  /* Schema, in-memory values & sorting                                     */
  /* ---------------------------------------------------------------------- */

  @cached
  get schemaDetectors(): EuiDataGridSchemaDetector[] {
    return [...providedSchemaDetectors, ...(this.args.schemaDetectors ?? [])];
  }

  /** Values read from the off-screen in-memory renderer. */
  inMemoryValues: EuiDataGridInMemoryValues = {};
  @tracked inMemoryVersion = 0;

  @action
  onCellRender(rowIndex: number, columnId: string, value: string): void {
    const row = (this.inMemoryValues[rowIndex] = this.inMemoryValues[rowIndex] || {});
    if (row[columnId] !== value) {
      row[columnId] = value;
      this.inMemoryVersion++;
    }
  }

  @action
  resetInMemoryValues(rowCount: number): void {
    for (const key of Object.keys(this.inMemoryValues)) {
      if (Number(key) >= rowCount) delete this.inMemoryValues[key];
    }
    this.inMemoryVersion++;
  }

  @cached
  get inMemoryValuesSnapshot(): EuiDataGridInMemoryValues {
    // read the version so consumers recompute after the renderer mutates values
    void this.inMemoryVersion;
    return { ...this.inMemoryValues };
  }

  get inMemoryRowCount(): number {
    const inMemory = this.args.inMemory;
    if (inMemory?.level === 'enhancements') {
      // only the first page size is guaranteed to be available in memory
      return this.pagination?.pageSize || this.dataRowCount; // ember-eui extension (row-tree): all data rows
    }
    return this.dataRowCount; // ember-eui extension (row-tree): all data rows
  }

  @cached
  get schema(): EuiDataGridSchema {
    const detected = detectSchema({
      columns: this.args.columns,
      inMemory: this.args.inMemory,
      inMemoryValues: this.args.inMemory ? this.inMemoryValuesSnapshot : {},
      schemaDetectors: this.schemaDetectors,
      autoDetectSchema: this.args.inMemory != null
    });
    return mergeSchema(detected, this.args.columns);
  }

  @cached
  get sortedRowMap(): number[] {
    return computeSortedRowMap({
      sorting: this.args.sorting,
      inMemory: this.args.inMemory,
      inMemoryValues:
        this.args.inMemory?.level === 'sorting' ? this.inMemoryValuesSnapshot : {},
      schema: this.schema,
      schemaDetectors: this.schemaDetectors
    });
  }

  /** Visible (page-relative or absolute) row index to the data row index. */
  @action
  getCorrectRowIndex(visibleRowIndex: number): number {
    const startRow = this.visibleRows.startRow;
    const isPaginated = visibleRowIndex - startRow < 0;
    const unpaginatedRowIndex = isPaginated
      ? visibleRowIndex + startRow
      : visibleRowIndex;
    // ember-eui extension (row-tree): tree rows (negative indexes for groups)
    if (this.rowModel) return this.rowModel.rowIndexAt(unpaginatedRowIndex);
    const sortedRowMap = this.sortedRowMap;
    return unpaginatedRowIndex in sortedRowMap
      ? sortedRowMap[unpaginatedRowIndex]!
      : unpaginatedRowIndex;
  }

  /* ---------------------------------------------------------------------- */
  /* Display options (gridStyle / rowHeightsOptions + display selector)     */
  /* ---------------------------------------------------------------------- */

  @cached
  get passedGridStyles(): EuiDataGridStyle {
    return { ...startingStyles, ...this.args.gridStyle };
  }

  @cached
  get passedGridStylesKey(): string {
    return stableKey(this.passedGridStyles);
  }

  // user changes from the display selector, valid until new styles are passed
  @tracked private gridStylesState: { key: string; styles: EuiDataGridStyle } | null =
    null;

  get gridStyles(): typeof startingStyles & EuiDataGridStyle {
    const state = this.gridStylesState;
    const styles =
      state && state.key === this.passedGridStylesKey
        ? state.styles
        : this.passedGridStyles;
    return styles as typeof startingStyles & EuiDataGridStyle;
  }

  /** Initial styles the display selector's reset button restores. */
  initialGridStyles: EuiDataGridStyle | null = null;

  @action
  onUserGridStyleChange(styles: Partial<EuiDataGridStyle>): void {
    const changed = { ...this.gridStyles, ...styles };
    const { onChange, ...rest } = changed;
    onChange?.(rest);
    this.gridStylesState = { key: this.passedGridStylesKey, styles: changed };
  }

  @cached
  get passedRowHeightsOptions(): EuiDataGridRowHeightsOptions {
    return this.args.rowHeightsOptions ?? {};
  }

  @cached
  get passedRowHeightsOptionsKey(): string {
    return stableKey(this.passedRowHeightsOptions);
  }

  @tracked private rowHeightsState: {
    key: string;
    options: EuiDataGridRowHeightsOptions;
  } | null = null;

  get rowHeightsOptions(): EuiDataGridRowHeightsOptions {
    const state = this.rowHeightsState;
    return state && state.key === this.passedRowHeightsOptionsKey
      ? state.options
      : this.passedRowHeightsOptions;
  }

  initialRowHeightsOptions: EuiDataGridRowHeightsOptions | null = null;

  @action
  onUserRowHeightChange(options: Partial<EuiDataGridRowHeightsOptions>): void {
    const changed = { ...this.rowHeightsOptions, ...options };
    const { onChange, ...rest } = changed;
    onChange?.(rest);
    this.rowHeightsState = { key: this.passedRowHeightsOptionsKey, options: changed };
  }

  @action
  resetDisplayOptions(): void {
    this.gridStylesState = {
      key: this.passedGridStylesKey,
      styles: this.initialGridStyles ?? this.passedGridStyles
    };
    this.rowHeightsState = {
      key: this.passedRowHeightsOptionsKey,
      options: this.initialRowHeightsOptions ?? this.passedRowHeightsOptions
    };
  }

  constructor(owner: Owner, args: EuiDataGridSignature['Args']) {
    super(owner, args);
    this.initialGridStyles = { ...startingStyles, ...args.gridStyle };
    this.initialRowHeightsOptions = args.rowHeightsOptions ?? {};
    // copies the focused cell's text on Ctrl/Cmd+C (static handler: deduped)
    document.addEventListener('copy', copyFocusedDataGridCell);
    // tabs/newlines for selections copied across cells (upstream
    // OverrideCopiedTabularContent; static handler: deduped)
    document.addEventListener('copy', onTabularCopy);
  }

  /* ---------------------------------------------------------------------- */
  /* Focus                                                                  */
  /* ---------------------------------------------------------------------- */

  private cellsUpdateFocus = new Map<string, CellCallback>();
  @tracked focusedCell: EuiDataGridFocusedCell | undefined = undefined;
  @tracked isFocusedCellInView = false;

  /** Register a cell's focus callback; returns the unregister function. */
  onFocusUpdate(cell: EuiDataGridFocusedCell, callback: CellCallback): () => void {
    const key = `${cell[0]}-${cell[1]}`;
    this.cellsUpdateFocus.set(key, callback);
    return () => {
      if (this.cellsUpdateFocus.get(key) === callback) this.cellsUpdateFocus.delete(key);
    };
  }

  isFocusedCell(colIndex: number, visibleRowIndex: number): boolean {
    const focused = this.focusedCell;
    return focused?.[0] === colIndex && focused?.[1] === visibleRowIndex;
  }

  @action
  setFocusedCell(nextFocusedCell: EuiDataGridFocusedCell, forceUpdate = false): void {
    const previous = this.focusedCell;
    if (
      !forceUpdate &&
      previous &&
      nextFocusedCell[0] === previous[0] &&
      nextFocusedCell[1] === previous[1]
    ) {
      return;
    }
    this.isFocusedCellInView = true; // scrolling ensures focused cells are in view
    this.focusedCell = nextFocusedCell;
    if (previous) this.notifyCell(previous, false);
    this.notifyCell(nextFocusedCell, true);
    this.body?.onFocusedCellChange(nextFocusedCell);
  }

  private notifyCell(cell: EuiDataGridFocusedCell, isFocused: boolean): void {
    this.cellsUpdateFocus.get(`${cell[0]}-${cell[1]}`)?.(isFocused);
  }

  @action
  setIsFocusedCellInView(isInView: boolean): void {
    if (this.isFocusedCellInView !== isInView) this.isFocusedCellInView = isInView;
  }

  @action
  focusFirstVisibleInteractiveCell(): void {
    this.setFocusedCell([0, -1]);
  }

  /* ---------------------------------------------------------------------- */
  /* Cell popover                                                           */
  /* ---------------------------------------------------------------------- */

  @tracked popoverCell: EuiDataGridCellLocation | null = null;
  /** Popover props a custom popover renderer sets (`setCellPopoverProps`). */
  @tracked cellPopoverProps: EuiDataGridCellPopoverProps = {};

  @action
  openCellPopover({ rowIndex, colIndex }: EuiDataGridCellLocation): void {
    const open = this.popoverCell;
    if (open && open.rowIndex === rowIndex && open.colIndex === colIndex) return;
    this.cellPopoverProps = {};
    this.popoverCell = { rowIndex, colIndex };
    this.body?.scrollCellIntoView({ rowIndex, colIndex });
  }

  @action
  closeCellPopover(): void {
    if (this.popoverCell) this.popoverCell = null;
  }

  isPopoverOpenFor(colIndex: number, visibleRowIndex: number): boolean {
    const open = this.popoverCell;
    return !!open && open.colIndex === colIndex && open.rowIndex === visibleRowIndex;
  }

  /* ---------------------------------------------------------------------- */
  /* Fullscreen                                                             */
  /* ---------------------------------------------------------------------- */

  @action
  setIsFullScreen(isFullScreen: boolean): void {
    if (this.isFullScreen === isFullScreen) return;
    this.isFullScreen = isFullScreen;
    this.args.onFullScreenChange?.(isFullScreen);
  }

  @action
  toggleFullScreen(): void {
    this.setIsFullScreen(!this.isFullScreen);
  }

  @action
  onGridRootKeyDown(event: KeyboardEvent): void {
    if (event.key === keys.ESCAPE && this.isFullScreen) {
      event.preventDefault();
      this.setIsFullScreen(false);
    }
  }

  restrictBody = modifier((_element: HTMLElement, [isFullScreen, bodyClass]: [boolean, string]) => {
    if (!isFullScreen) return;
    document.body.classList.add(GRID_IS_FULLSCREEN_CLASSNAME, bodyClass);
    return () => {
      document.body.classList.remove(GRID_IS_FULLSCREEN_CLASSNAME, bodyClass);
    };
  });

  /* ---------------------------------------------------------------------- */
  /* Toolbar                                                                */
  /* ---------------------------------------------------------------------- */

  get showToolbar(): boolean {
    return !!(this.args.toolbarVisibility ?? true);
  }

  get showHeader(): boolean {
    return !!(this.args.headerVisibility ?? true);
  }

  /* ---------------------------------------------------------------------- */
  /* Styles & classes                                                       */
  /* ---------------------------------------------------------------------- */

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    return {
      context,
      grid: useEuiBorealisStyles(context, euiDataGridStyles),
      fullScreen: useEuiBorealisStyles(context, euiDataGridFullScreenStyles)
    };
  }

  @cached
  get focusWrapClass(): string {
    const { context, grid } = this.styles;
    return `euiDataGrid__focusWrap ${euiClass(context, grid.euiDataGrid__focusWrap)}`;
  }

  @cached
  get fullScreenClass(): string {
    const { context, fullScreen } = this.styles;
    return euiClass(context, fullScreen['euiDataGrid--fullScreen']);
  }

  @cached
  get restrictBodyClass(): string {
    const { context, fullScreen } = this.styles;
    return euiClass(context, fullScreen.euiDataGrid__restrictBody);
  }

  @cached
  get classes(): string {
    const { context, grid } = this.styles;
    const gridStyles = this.gridStyles;
    const toolbarVisibility = this.args.toolbarVisibility ?? true;
    return [
      'euiDataGrid',
      fontSizesToClassMap[gridStyles.fontSize],
      bordersToClassMap[gridStyles.border],
      headerToClassMap[gridStyles.header],
      footerToClassMap[gridStyles.footer],
      rowHoverToClassMap[gridStyles.rowHover],
      cellPaddingsToClassMap[gridStyles.cellPadding],
      gridStyles.stripes && 'euiDataGrid--stripes',
      gridStyles.footer && gridStyles.stickyFooter && 'euiDataGrid--stickyFooter',
      this.isFullScreen && 'euiDataGrid--fullScreen',
      this.isFullScreen && this.fullScreenClass,
      !toolbarVisibility && 'euiDataGrid--noControls',
      !this.showHeader && 'euiDataGrid--noHeader',
      euiClass(
        context,
        BOX_SIZING_RESET,
        grid.euiDataGrid,
        grid.cellPadding[gridStyles.cellPadding],
        grid.fontSize[gridStyles.fontSize],
        grid.borders[gridStyles.border],
        this.args.css
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  /** Class of the hidden tabular copy marker characters. */
  @cached
  get copyMarkerClass(): string {
    return euiScreenReaderOnlyClass(this.styles.context);
  }

  @cached
  get contentClass(): string {
    const { context, grid } = this.styles;
    return `euiDataGrid__content ${euiClass(context, grid.euiDataGrid__content)}`;
  }

  get rootStyle() {
    if (this.isFullScreen) return undefined;
    const toCss = (value: string | number | undefined) =>
      typeof value === 'number' ? `${value}px` : value;
    const width = toCss(this.args.width);
    const height = toCss(this.args.height);
    if (!width && !height) return undefined;
    return htmlSafe(
      [width && `width:${width}`, height && `height:${height}`].filter(Boolean).join(';')
    );
  }

  /* ---------------------------------------------------------------------- */
  /* Accessibility                                                          */
  /* ---------------------------------------------------------------------- */

  get ariaPage(): number {
    return this.pagination ? this.pagination.pageIndex + 1 : 1;
  }

  get ariaPageCount(): number {
    return this.pagination?.pageSize
      ? Math.ceil(this.rowCount / this.pagination.pageSize) // ember-eui extension (row-tree): visible rows
      : 1;
  }

  get rawAriaLabel(): string | null {
    return this.args.ariaLabel ?? this.attrAriaLabel;
  }

  get rawAriaLabelledBy(): string | null {
    return this.args.ariaLabelledBy ?? this.attrAriaLabelledBy;
  }

  get gridAriaLabel(): string | undefined {
    const label = this.rawAriaLabel;
    if (label == null) return undefined;
    if (!this.pagination) return label;
    return this.euiI18n.lookupToken(
      'euiDataGrid.ariaLabel',
      '{label}; Page {page} of {pageCount}.',
      { label, page: this.ariaPage, pageCount: this.ariaPageCount }
    );
  }

  get gridAriaLabelledBy(): string | undefined {
    const labelledBy = this.rawAriaLabelledBy;
    if (labelledBy == null) return undefined;
    return `${labelledBy} ${this.pagination ? this.ariaLabelledById : ''}`;
  }

  get ariaLabelledByText(): string {
    return this.euiI18n.lookupToken(
      'euiDataGrid.ariaLabelledBy',
      'Page {page} of {pageCount}.',
      { page: this.ariaPage, pageCount: this.ariaPageCount }
    );
  }

  get screenReaderNotice(): string {
    return this.euiI18n.lookupToken(
      'euiDataGrid.screenReaderNotice',
      'Cell contains interactive content.'
    );
  }

  /** Moves `aria-label`/`aria-labelledby` attributes to the `role=grid` element. */
  moveAriaAttributes = modifier((element: HTMLElement) => {
    const move = () => {
      for (const name of ['aria-label', 'aria-labelledby'] as const) {
        if (element.hasAttribute(name)) {
          const value = element.getAttribute(name);
          element.removeAttribute(name);
          if (name === 'aria-label') this.attrAriaLabel = value;
          else this.attrAriaLabelledBy = value;
        }
      }
    };
    afterRender(this, move);
    const observer = new MutationObserver(move);
    observer.observe(element, { attributeFilter: ['aria-label', 'aria-labelledby'] });
    return () => observer.disconnect();
  });

  /** Tracks the grid width for the toolbar's responsive controls. */
  observeWidth = modifier((element: HTMLElement) => {
    const update = () => {
      const width = element.offsetWidth;
      if (width !== this.gridWidth) this.gridWidth = width;
    };
    afterRender(this, update);
    return observeResize([element], update);
  });

  /** Interactive elements added to cells leave the tab order. */
  setupContent = modifier((element: HTMLElement) => {
    this.contentElement = element;
    const observer = new MutationObserver(preventTabbing);
    observer.observe(element, { subtree: true, childList: true });
    return () => {
      observer.disconnect();
      this.contentElement = null;
    };
  });

  /* ---------------------------------------------------------------------- */
  /* Content keyboard handling                                              */
  /* ---------------------------------------------------------------------- */

  get hasFooter(): boolean {
    return this.body?.hasFooter ?? !!this.args.renderFooterCellValue;
  }

  @action
  onContentKeyDown(event: KeyboardEvent): void {
    // Popovers attached inside cells (expansion, column actions) own their
    // keys: upstream renders them outside the grid content
    if ((event.target as Element | null)?.closest?.('.euiPopover__panel')) return;
    handleGridKeyDown(event, {
      gridElement: this.contentElement,
      visibleColCount: this.visibleColCount,
      visibleRowCount: this.visibleRows.visibleRowCount,
      visibleRowStartIndex: this.body?.visibleRowStartIndex ?? 0,
      rowCount: this.rowCount, // ember-eui extension (row-tree): visible rows
      pagination: this.pagination,
      hasFooter: this.hasFooter,
      focusedCell: this.focusedCell,
      setFocusedCell: this.setFocusedCell
    });
  }

  get contentTabIndex(): number {
    // Firefox allows tabbing to a scrollable div, Chrome does not
    return this.isFocusedCellInView ? -1 : 0;
  }

  @action
  onContentKeyUp(event: KeyboardEvent): void {
    if (this.isFocusedCellInView) return;
    // Only move focus into the grid on a keyboard tab: mouse users can
    // accidentally focus the wrapper by clicking scrollbars
    if (event.key === keys.TAB && event.target === event.currentTarget) {
      this.focusFirstVisibleInteractiveCell();
    }
  }

  willDestroy(): void {
    super.willDestroy();
    this.body = null;
  }

  /* ---------------------------------------------------------------------- */
  /* Imperative API (upstream `useImperativeGridRef`)                       */
  /* ---------------------------------------------------------------------- */

  /**
   * Throws a digestible error if the consumer targets an invalid cell, which
   * also stops the API from continuing.
   */
  private checkCellExists({ rowIndex, colIndex }: EuiDataGridCellLocationProps): void {
    const rowCount = this.dataRowCount; // ember-eui extension (row-tree): all data rows
    const colCount = this.visibleColCount;
    if (rowIndex >= rowCount || rowIndex < 0) {
      throw new Error(
        `Row ${rowIndex} is not a valid row. The maximum visible row index is ${rowCount - 1}.`
      );
    }
    if (colIndex >= colCount) {
      throw new Error(
        `Column ${colIndex} is not a valid column. The maximum visible column index is ${colCount - 1}.`
      );
    }
  }

  /**
   * The consumer's (unsorted, unpaginated) row index to the visible row
   * index the cells use, changing page when the row is on another one.
   */
  private findVisibleRowIndex(rowIndex: number): number {
    const sortedRowMap = this.sortedRowMap;
    const visibleRowIndex = this.rowModel // ember-eui extension (row-tree): reveals collapsed rows
      ? this.rowModel.findVisibleRowIndex(rowIndex)
      : sortedRowMap.length
      ? sortedRowMap.findIndex((mappedIndex) => mappedIndex === rowIndex)
      : rowIndex;
    const pagination = this.pagination;
    if (pagination && pagination.pageSize > 0) {
      const pageIndex = Math.floor(visibleRowIndex / pagination.pageSize);
      if (pageIndex !== pagination.pageIndex) pagination.onChangePage(pageIndex);
      return visibleRowIndex % pagination.pageSize;
    }
    return visibleRowIndex;
  }

  /** The API passed to `@registerApi`. */
  readonly api: EuiDataGridRefProps = {
    setIsFullScreen: (isFullScreen: boolean) => this.setIsFullScreen(isFullScreen),
    setFocusedCell: (cell: EuiDataGridCellLocationProps) => {
      this.checkCellExists(cell);
      const visibleRowIndex = this.findVisibleRowIndex(cell.rowIndex);
      // forced, unlike upstream: re-focuses the cell even when it is
      // already the grid's focused cell (e.g. after a modal or popover)
      this.setFocusedCell([cell.colIndex, visibleRowIndex], true);
    },
    openCellPopover: (cell: EuiDataGridCellLocationProps) => {
      this.checkCellExists(cell);
      const visibleRowIndex = this.findVisibleRowIndex(cell.rowIndex);
      this.openCellPopover({ rowIndex: visibleRowIndex, colIndex: cell.colIndex });
    },
    closeCellPopover: () => this.closeCellPopover(),
    scrollTo: (params) => this.body?.scrollTo?.(params),
    scrollToItem: (params) => this.body?.scrollToItem?.(params)
  };

  // ember-eui extension (row-tree): toggles a row (closes a popover: rows below it move)
  @action
  toggleRow(row: { id: string; kind: 'row' | 'group'; isExpanded: boolean }): void {
    this.closeCellPopover();
    this.rowModel?.toggle(row);
  }

  // ember-eui extension (row-tree): re-registers the API when the tree state appears
  get hasRowModel(): boolean {
    return !!this.rowModel;
  }

  clampRowTreePageIndex = clampRowTreePageIndex; // ember-eui extension (row-tree): see row-tree-hooks.ts

  registerApi = modifier(
    (
      _element: HTMLElement,
      [registerApi, hasRowModel]: [EuiDataGridSignature['Args']['registerApi'], boolean]
    ) => {
      // ember-eui extension (row-tree): expand/collapse API methods
      const api = hasRowModel ? { ...this.api, ...this.rowTreeModel.api } : this.api;
      if (registerApi) afterRender(this, () => registerApi(api));
    }
  );

  <template>
    <div
      class={{this.focusWrapClass}}
      {{focusTrap
          _createFocusTrap=focusTrapFactory
        isActive=this.isFullScreen
        focusTrapOptions=(hash
          clickOutsideDeactivates=true escapeDeactivates=false preventScroll=true
        )
      }}
    >
      <div
        class={{this.classes}}
        style={{this.rootStyle}}
        {{on "keydown" this.onGridRootKeyDown}}
        {{this.observeWidth}}
        {{this.restrictBody this.isFullScreen this.restrictBodyClass}}
        {{! ember-eui extension (row-tree): re-register the API with tree methods }}
        {{this.registerApi @registerApi this.hasRowModel}}
        {{! ember-eui extension (row-tree): page index clamping }}
        {{this.clampRowTreePageIndex this this.rowCount this.pagination.pageIndex this.pagination.pageSize}}
        ...attributes
        {{this.moveAriaAttributes}}
      >
        {{#if this.showToolbar}}
          <EuiDataGridToolbar @grid={{this}} @hasCustomToolbarBlock={{has-block "customToolbar"}}>
            <:leftControlsPrepend>{{yield to="leftControlsPrepend"}}</:leftControlsPrepend>
            <:leftControlsAppend>{{yield to="leftControlsAppend"}}</:leftControlsAppend>
            <:rightControls>{{yield to="rightControls"}}</:rightControls>
            <:customToolbar as |toolbar|>{{yield toolbar to="customToolbar"}}</:customToolbar>
          </EuiDataGridToolbar>
        {{/if}}
        {{#if @inMemory}}
          <EuiDataGridInMemoryRenderer
            @grid={{this}}
            @inMemory={{@inMemory}}
            @rowCount={{this.inMemoryRowCount}}
          >
            <:cell as |cell|>{{yield cell to="cell"}}</:cell>
          </EuiDataGridInMemoryRenderer>
        {{/if}}
        {{! template-lint-disable no-invalid-interactive }}
        <div
          id={{this.gridId}}
          class={{this.contentClass}}
          {{! ember-eui extension (row-tree): treegrid role, visible row count }}
          role={{if this.rowModel "treegrid" "grid"}}
          aria-rowcount={{this.rowCount}}
          aria-colcount={{this.visibleColCount}}
          aria-label={{this.gridAriaLabel}}
          aria-labelledby={{this.gridAriaLabelledBy}}
          tabindex={{this.contentTabIndex}}
          data-test-subj="euiDataGridBody"
          {{on "keydown" this.onContentKeyDown}}
          {{on "keyup" this.onContentKeyUp}}
          {{this.setupContent}}
        >
          <EuiDataGridCopyMarker @grid={{this}} @type="boundary" />
          {{#if (or @renderCustomGridBody (has-block "customGridBody"))}}
            <EuiDataGridCustomBody
              @grid={{this}}
              @hasFooterBlock={{has-block "footerCell"}}
              @renderCustomGridBody={{@renderCustomGridBody}}
            >
              <:customGridBody as |body|>{{yield body to="customGridBody"}}</:customGridBody>
            </EuiDataGridCustomBody>
          {{else}}
            <EuiDataGridBody
              @grid={{this}}
              @hasFooterBlock={{has-block "footerCell"}}
              @hasCellPopoverBlock={{has-block "cellPopover"}}
            >
              <:cell as |cell|>{{yield cell to="cell"}}</:cell>
              <:cellPopover as |popover|>{{yield popover to="cellPopover"}}</:cellPopover>
              <:footerCell as |cell|>{{yield cell to="footerCell"}}</:footerCell>
              <:controlHeaderCell as |cell|>{{yield cell to="controlHeaderCell"}}</:controlHeaderCell>
              <:controlCell as |cell|>{{yield cell to="controlCell"}}</:controlCell>
              <:controlFooterCell as |cell|>{{yield cell to="controlFooterCell"}}</:controlFooterCell>
            </EuiDataGridBody>
          {{/if}}
          <EuiDataGridCopyMarker @grid={{this}} @type="boundary" />
        </div>
        {{#if this.showPagination}}
          {{#if this.rawAriaLabelledBy}}
            <p id={{this.ariaLabelledById}} hidden>{{this.ariaLabelledByText}}</p>
          {{/if}}
          <EuiDataGridPagination @grid={{this}} @pagination={{this.definedPagination}} />
        {{/if}}
        <p id={{this.interactiveCellId}} hidden>{{this.screenReaderNotice}}</p>
      </div>
    </div>
  </template>
}
