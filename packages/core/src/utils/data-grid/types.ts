/*
 * Types for EuiDataGrid, ported from EUI 123.1.0
 * `components/datagrid/data_grid_types.ts`. React render props become Ember
 * components (or named blocks on `EuiDataGrid`).
 */
import type { ComponentLike } from '@glint/template';

export type EuiDataGridStyleFontSizes = 's' | 'm' | 'l';
export type EuiDataGridStyleBorders = 'all' | 'horizontal' | 'none';
export type EuiDataGridStyleHeader = 'shade' | 'underline';
export type EuiDataGridStyleFooter = 'shade' | 'overline' | 'striped';
export type EuiDataGridStyleRowHover = 'highlight' | 'none';
export type EuiDataGridStyleCellPaddings = 's' | 'm' | 'l';

export interface EuiDataGridStyle {
  fontSize?: EuiDataGridStyleFontSizes;
  border?: EuiDataGridStyleBorders;
  stripes?: boolean;
  header?: EuiDataGridStyleHeader;
  footer?: EuiDataGridStyleFooter;
  stickyFooter?: boolean;
  rowHover?: EuiDataGridStyleRowHover;
  cellPadding?: EuiDataGridStyleCellPaddings;
  /** Extra classes per row index (data index), e.g. `{ 3: 'myRow' }`. */
  rowClasses?: Record<number, string>;
  /** Called with the new styles when the display selector changes them. */
  onChange?: (styles: EuiDataGridStyle) => void;
}

export type EuiDataGridRowHeightOption =
  | number
  | 'auto'
  | { lineCount: number; height?: never }
  | { height: number; lineCount?: never };

export interface EuiDataGridRowHeightsOptions {
  defaultHeight?: EuiDataGridRowHeightOption;
  rowHeights?: Record<number, EuiDataGridRowHeightOption>;
  lineHeight?: string;
  autoBelowLineCount?: boolean;
  /**
   * The row anchoring vertical layout shifts: with `'start'` or `'center'`
   * the first or middle visible row keeps its position when rows above it
   * change height, by adjusting the grid's scroll position.
   */
  scrollAnchorRow?: 'start' | 'center';
  onChange?: (options: EuiDataGridRowHeightsOptions) => void;
}

/** Props a cell renderer may set on its cell (`setCellProps`). */
export interface EuiDataGridSetCellProps {
  className?: string;
  style?: Record<string, string | number | undefined>;
  isExpandable?: boolean;
  'data-test-subj'?: string;
  [attribute: string]: unknown;
}

/** Arguments of `@renderCellValue` / the `<:cell>` block. */
export interface EuiDataGridCellValueElementProps {
  rowIndex: number;
  colIndex: number;
  columnId: string;
  setCellProps: (props: EuiDataGridSetCellProps) => void;
  isExpandable: boolean;
  isExpanded: boolean;
  isDetails: boolean;
  schema?: string | null;
  cellContext?: Record<string, unknown>;
}

export interface EuiDataGridCellValueSignature {
  Args: EuiDataGridCellValueElementProps;
}

/** Arguments of a column cell action component. */
export interface EuiDataGridColumnCellActionProps {
  rowIndex: number;
  colIndex: number;
  columnId: string;
  /** The button to render: an EuiButtonIcon on hover, EuiButtonEmpty in the popover. */
  Component: ComponentLike<{
    Element: HTMLButtonElement | HTMLAnchorElement;
    Args: { iconType?: string; isDisabled?: boolean };
    Blocks: { default: [] };
  }>;
  isExpanded: boolean;
}

/**
 * A cell action: an Ember component (upstream API) or, as an Ember
 * convenience, a descriptor rendered with the cell action button.
 */
export type EuiDataGridColumnCellAction =
  | ComponentLike<{ Args: EuiDataGridColumnCellActionProps }>
  | {
      iconType: string;
      label: string;
      onClick: (props: Omit<EuiDataGridColumnCellActionProps, 'Component'>) => void;
      'data-test-subj'?: string;
    };

export interface EuiDataGridColumnActionConfig {
  label?: string;
  iconType?: string;
  isDisabled?: boolean;
  [key: string]: unknown;
}

export interface EuiDataGridColumnActions {
  showHide?: boolean | EuiDataGridColumnActionConfig;
  showMoveLeft?: boolean | EuiDataGridColumnActionConfig;
  showMoveRight?: boolean | EuiDataGridColumnActionConfig;
  showSortAsc?: boolean | EuiDataGridColumnActionConfig;
  showSortDesc?: boolean | EuiDataGridColumnActionConfig;
  /** Extra `EuiListGroupItem` arguments (`label`, `iconType`, `onClick`, …). */
  additional?: EuiDataGridColumnActionConfig[];
}

export interface EuiDataGridColumn {
  id: string;
  /** Header content component; falls back to `displayAsText` or `id`. */
  display?: ComponentLike;
  displayAsText?: string;
  /** Extra attributes for the header cell (`className`, `data-*`, …). */
  displayHeaderCellProps?: Record<string, unknown> & { className?: string };
  initialWidth?: number;
  isResizable?: boolean;
  isExpandable?: boolean;
  isSortable?: boolean;
  defaultSortDirection?: 'asc' | 'desc';
  schema?: string;
  actions?: false | EuiDataGridColumnActions;
  cellActions?: EuiDataGridColumnCellAction[];
  visibleCellActions?: number;
}

export interface EuiDataGridControlColumn {
  id: string;
  width: number;
  /** Header component; or use the `<:controlHeaderCell>` block. */
  headerCellRender?: ComponentLike;
  headerCellProps?: Record<string, unknown> & { className?: string };
  /** Body cell component; or use the `<:controlCell>` block. */
  rowCellRender?: ComponentLike<EuiDataGridCellValueSignature>;
  /** Footer cell component; or use the `<:controlFooterCell>` block. */
  footerCellRender?: ComponentLike<EuiDataGridCellValueSignature>;
  footerCellProps?: Record<string, unknown> & { className?: string };
}

export interface EuiDataGridColumnVisibility {
  visibleColumns: string[];
  setVisibleColumns: (columnIds: string[]) => void;
  canDragAndDropColumns?: boolean;
}

export interface EuiDataGridSortingColumn {
  id: string;
  direction: 'asc' | 'desc';
}

export interface EuiDataGridSorting {
  onSort: (columns: EuiDataGridSortingColumn[]) => void;
  columns: EuiDataGridSortingColumn[];
}

export interface EuiDataGridPaginationProps {
  pageIndex: number;
  pageSize?: number;
  pageSizeOptions?: number[];
  onChangePage: (pageIndex: number) => void;
  onChangeItemsPerPage: (pageSize: number) => void;
}

export interface EuiDataGridInMemory {
  level: 'enhancements' | 'pagination' | 'sorting';
  skipColumns?: string[];
}

export type EuiDataGridInMemoryValues = Record<
  string,
  Record<string, string>
>;

export interface EuiDataGridSchemaDetector {
  type: string;
  detector: (value: string) => number;
  comparator?: (
    a: string,
    b: string,
    direction: 'asc' | 'desc',
    indexes: { aIndex: number; bIndex: number }
  ) => number;
  icon: string;
  color?: string;
  /** Sort labels: plain text or an i18n `{ token, default }` pair. */
  sortTextAsc: string | { token: string; default: string };
  sortTextDesc: string | { token: string; default: string };
  isSortable?: boolean;
  defaultSortDirection?: 'asc' | 'desc';
  textTransform?: 'uppercase' | 'lowercase' | 'capitalize';
}

export type EuiDataGridSchema = Record<string, { columnType: string | null }>;

export interface EuiDataGridToolBarVisibilityColumnSelectorOptions {
  allowHide?: boolean;
  allowReorder?: boolean;
}

export interface EuiDataGridToolBarVisibilityDisplaySelectorOptions {
  allowDensity?: boolean;
  allowRowHeight?: boolean;
  allowResetButton?: boolean;
  /** A component appended to the bottom of the display settings popover. */
  additionalDisplaySettings?: ComponentLike;
  /**
   * Completely custom layout of the display settings popover: a component
   * receiving the default controls (undefined when disabled).
   */
  customRender?: ComponentLike<{ Args: EuiDataGridDisplaySelectorCustomRenderProps }>;
}

/** Arguments of `showDisplaySelector.customRender`. */
export interface EuiDataGridDisplaySelectorCustomRenderProps {
  densityControl?: ComponentLike;
  rowHeightControl?: ComponentLike;
  additionalDisplaySettings?: ComponentLike;
  resetButton?: ComponentLike;
}

/** Where `toolbarVisibility.additionalControls.left` components go. */
export interface EuiDataGridToolBarAdditionalControlsLeftOptions {
  /** Before the column & sort controls. */
  prepend?: ComponentLike;
  /** After the column & sort controls. */
  append?: ComponentLike;
}

export interface EuiDataGridToolBarAdditionalControlsOptions {
  /**
   * A component appended to the left side (after the column & sort
   * controls), or `{ prepend, append }` components.
   */
  left?: ComponentLike | EuiDataGridToolBarAdditionalControlsLeftOptions;
  /** A component prepended to the right side (before the display & fullscreen controls). */
  right?: ComponentLike;
}

export interface EuiDataGridToolBarVisibilityOptions {
  showColumnSelector?:
    | boolean
    | EuiDataGridToolBarVisibilityColumnSelectorOptions;
  showDisplaySelector?:
    | boolean
    | EuiDataGridToolBarVisibilityDisplaySelectorOptions;
  showSortSelector?: boolean;
  showFullScreenSelector?: boolean;
  /**
   * Shows the keyboard shortcuts popover button. When `false`, it is
   * visually hidden but still reachable by keyboard and screen readers.
   */
  showKeyboardShortcuts?: boolean;
  /**
   * Extra toolbar controls as components: one component (appended to the
   * left side) or `{ left, right }` (see also the grid's
   * `<:leftControlsPrepend>`, `<:leftControlsAppend>` and `<:rightControls>`
   * blocks).
   */
  additionalControls?: ComponentLike | EuiDataGridToolBarAdditionalControlsOptions;
}

/** Controls handed to `@renderCustomToolbar` / the `<:customToolbar>` block (undefined when hidden). */
export interface EuiDataGridCustomToolbarProps {
  /** Whether the grid is wide enough (or fullscreen) for the left controls. */
  hasRoomForGridControls: boolean;
  /** The column selector button. */
  columnControl?: ComponentLike;
  /** The sort popover button (undefined without `@sorting`). */
  columnSortingControl?: ComponentLike;
  /** The keyboard shortcuts button (screen reader only when `showKeyboardShortcuts` is false). */
  keyboardShortcutsControl: ComponentLike;
  /** The display options button. */
  displayControl?: ComponentLike;
  /** The fullscreen toggle. */
  fullScreenControl?: ComponentLike;
  /**
   * Ember addition: `toolbarVisibility.additionalControls` components by
   * position (the grid's control blocks can't be passed on).
   */
  additionalControls: {
    leftPrepend?: ComponentLike;
    leftAppend?: ComponentLike;
    right?: ComponentLike;
  };
}

export interface EuiDataGridVirtualizationOptions {
  /** Extra class of the scrolling body element. */
  className?: string;
  /** Extra inline styles of the scrolling body element. */
  style?: Record<string, string | number>;
  /** Initial vertical scroll offset in px. */
  initialScrollTop?: number;
  /** Initial horizontal scroll offset in px. */
  initialScrollLeft?: number;
  /** Extra rows rendered above/below the viewport. Defaults to 1. */
  overscanRowCount?: number;
  /** Extra columns rendered before/after the viewport. Defaults to 1. */
  overscanColumnCount?: number;
  onItemsRendered?: (items: EuiDataGridItemsRendered) => void;
  onScroll?: (event: EuiDataGridScrollEvent) => void;
}

export interface EuiDataGridItemsRendered {
  overscanRowStartIndex: number;
  overscanRowStopIndex: number;
  overscanColumnStartIndex: number;
  overscanColumnStopIndex: number;
  visibleRowStartIndex: number;
  visibleRowStopIndex: number;
  visibleColumnStartIndex: number;
  visibleColumnStopIndex: number;
}

export interface EuiDataGridScrollEvent {
  scrollTop: number;
  scrollLeft: number;
  scrollHeight: number;
  scrollWidth: number;
  clientHeight: number;
  clientWidth: number;
  isScrolledToBlockStart: boolean;
  isScrolledToBlockEnd: boolean;
  isScrolledToInlineStart: boolean;
  isScrolledToInlineEnd: boolean;
}

/** `[colIndex, visibleRowIndex]`; the header row is `-1`. */
export type EuiDataGridFocusedCell = [number, number];

/** Cell location used by the imperative API (`rowIndex` is the data row index). */
export interface EuiDataGridCellLocationProps {
  rowIndex: number;
  colIndex: number;
}

/** react-window `scrollTo` arguments: offsets in px, missing ones are kept. */
export interface EuiDataGridScrollToProps {
  scrollLeft?: number;
  scrollTop?: number;
}

/** react-window `scrollToItem` arguments (`rowIndex` is the visible row index). */
export interface EuiDataGridScrollToItemProps {
  align?: 'auto' | 'smart' | 'center' | 'end' | 'start';
  columnIndex?: number;
  rowIndex?: number;
}

/**
 * The grid's imperative API (upstream's `ref`), passed to `@registerApi`.
 */
export interface EuiDataGridRefProps {
  /** Allows manually controlling the fullscreen state of the grid. */
  setIsFullScreen: (isFullScreen: boolean) => void;
  /**
   * Focuses the specified cell, changing page if needed. Restore focus to
   * the grid with it after closing a modal or flyout the grid opened.
   */
  setFocusedCell: (cell: EuiDataGridCellLocationProps) => void;
  /** Opens the expansion popover of the specified cell, changing page if needed. */
  openCellPopover: (cell: EuiDataGridCellLocationProps) => void;
  /** Closes any open cell popover. */
  closeCellPopover: () => void;
  /** Scrolls the grid body to a top/left offset (not available with a custom grid body). */
  scrollTo?: (params: EuiDataGridScrollToProps) => void;
  /** Scrolls a row and/or column into view (not available with a custom grid body). */
  scrollToItem?: (params: EuiDataGridScrollToItemProps) => void;
}
