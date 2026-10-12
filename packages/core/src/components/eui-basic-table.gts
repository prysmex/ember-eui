import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { next } from '@ember/runloop';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';

import { modifier } from 'ember-modifier';

import {
  elementProps,
  getAlignForDataType,
  getCellProps,
  getItemId,
  getRendererForDataType,
  getRowProps
} from '../-private/basic-table.ts';
import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiBasicTableBodyLoading,
  euiBasicTableWrapperPanelledStyles,
  euiTableCaptionStyles
} from '../utils/eui/styles.generated.ts';
import { get } from '../utils/eui/search-bar/predicate.ts';
import { SortDirection } from '../utils/eui/sort.ts';
import CollapsedItemActions from './eui-basic-table/collapsed-item-actions.gts';
import ExpandedItemActions from './eui-basic-table/expanded-item-actions.gts';
import PaginationBar, {
  PAGINATION_DEFAULTS
} from './eui-basic-table/pagination-bar.gts';
import EuiCheckbox from './eui-checkbox.gts';
import EuiDelayRender from './eui-delay-render.gts';
import EuiIcon from './eui-icon.gts';
import EuiIconTip from './eui-icon-tip.gts';
import { euiScreenReaderOnlyCss } from './eui-screen-reader-only.gts';
import EuiTable from './eui-table.gts';
import EuiTableBody from './eui-table-body.gts';
import EuiTableFooter from './eui-table-footer.gts';
import EuiTableFooterCell from './eui-table-footer-cell.gts';
import EuiTableHeader from './eui-table-header.gts';
import EuiTableHeaderCell from './eui-table-header-cell.gts';
import EuiTableHeaderCellCheckbox from './eui-table-header-cell-checkbox.gts';
import EuiTableHeaderMobile from './eui-table-header-mobile.gts';
import EuiTableRow from './eui-table-row.gts';
import EuiTableRowCell from './eui-table-row-cell.gts';
import EuiTableRowCellCheckbox from './eui-table-row-cell-checkbox.gts';
import EuiTableSortMobile from './eui-table-sort-mobile.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type {
  Action,
  CellPropsCallback,
  Criteria,
  CriteriaWithPagination,
  EuiBasicTableColumn,
  EuiTableActionsColumnType,
  EuiTableCellComponent,
  EuiTableColumnNameTooltipProps,
  EuiTableComputedColumnType,
  EuiTableContent,
  EuiTableElementProps,
  EuiTableFieldDataColumnType,
  EuiTableSelectionType,
  EuiTableSortingType,
  ItemId,
  ItemIdResolved,
  Pagination,
  RowPropsCallback
} from '../-private/basic-table.ts';
import type {
  TableAlignment,
  TableMobileOptions,
  TableResponsiveBreakpoint
} from '../-private/table.ts';
import type EuiI18n from '../services/eui-i18n';
import type { EuiTableSortMobileItemOption } from './eui-table-sort-mobile.gts';

export type {
  Action,
  CellPropsCallback,
  Criteria,
  CriteriaWithPagination,
  CustomItemAction,
  DefaultItemAction,
  EuiBasicTableColumn,
  EuiTableActionsColumnType,
  EuiTableCellComponentArgs,
  EuiTableColumnNameTooltipProps,
  EuiTableComputedColumnType,
  EuiTableContent,
  EuiTableDataType,
  EuiTableFieldDataColumnType,
  EuiTableFooterProps,
  EuiTableSelectionType,
  EuiTableSortingType,
  ItemId,
  Pagination,
  RowPropsCallback
} from '../-private/basic-table.ts';
export { getItemId } from '../-private/basic-table.ts';

/**
 * A table built from `@items` and `@columns` (field, computed and actions
 * columns), with optional sorting, pagination, selection and expanded
 * rows. It renders the state you pass and calls `@onChange` with the new
 * `{ page, sort }` criteria; use `EuiInMemoryTable` to let the table own
 * that state.
 */
export interface EuiBasicTableSignature<T extends object> {
  Element: HTMLDivElement;
  Args: {
    /** The rows' items. */
    items: T[];
    /**
     * The columns: field data (`{ field, name, dataType, render,
     * component, sortable, … }`), computed (`{ render | component, name }`)
     * and actions (`{ actions, name }`).
     */
    columns: Array<EuiBasicTableColumn<T>>;
    /** How to get a unique id of an item (a key or a function), for selection and expanded rows. */
    itemId?: ItemId<T>;
    /**
     * Expanded rows by item id: a text, or any truthy value rendered by
     * the `<:expandedRow>` block.
     */
    itemIdToExpandedRowMap?: Record<string, unknown>;
    /** Attributes of every row cell, or a function of the item and column. */
    cellProps?: EuiTableElementProps | CellPropsCallback<T>;
    /** Attributes of every row (`onClick` makes rows clickable), or a function of the item. */
    rowProps?: EuiTableElementProps | RowPropsCallback<T>;
    /** Error message shown instead of the rows. */
    error?: string;
    /** Describes the table for screen readers. Defaults to "Data table". */
    tableCaption?: string;
    /** The `field` of the column whose cells are the rows' headers (`<th scope="row">`). */
    rowHeader?: string;
    /** Shows a loading line above the rows. */
    loading?: boolean;
    /**
     * Panelled look of the table and its pagination, for tables outside
     * EUI containers (like `EuiPanel` or `EuiFlyout`).
     */
    panelled?: boolean;
    /** Message when there are no items. Defaults to "No items found". */
    noItemsMessage?: string;
    /**
     * Called with the new `{ page, sort }` criteria when the user pages or
     * sorts (required with `@pagination` or `@sorting`).
     */
    onChange?: (criteria: Criteria<T> & CriteriaWithPagination<T>) => void;
    /** `{ pageIndex, pageSize, totalItemCount, pageSizeOptions, showPerPageOptions }`. */
    pagination?: Pagination;
    /** `{ onSelectionChange, selectable, selectableMessage, initialSelected, selected }`. */
    selection?: EuiTableSelectionType<T>;
    /** `{ sort: { field, direction }, enableAllColumns, readOnly }`. */
    sorting?: EuiTableSortingType<T>;
    /** `'fixed'` or `'auto'`. Defaults to `'fixed'`. */
    tableLayout?: 'fixed' | 'auto';
    /** Smaller text and padding. */
    compressed?: boolean;
    /** Breakpoint below which rows become cards (`true` always, `false` never). Defaults to `'m'`. */
    responsiveBreakpoint?: TableResponsiveBreakpoint;
    /** The table's plain background. Defaults to `true`. */
    hasBackground?: boolean;
    /** Lets the table scroll inline (upstream beta). */
    scrollableInline?: boolean;
    /** @private Whether the caller's `<:expandedRow>` block exists (when forwarding it). */
    hasExpandedRowBlock?: boolean;
    /** @private Whether the caller's `<:noItemsMessage>` block exists (when forwarding it). */
    hasNoItemsBlock?: boolean;
  };
  Blocks: {
    /** Content of an expanded row; yields the item, its id and its map value. */
    expandedRow: [item: T, itemId: ItemIdResolved, value: unknown];
    /** Content shown when there are no items (instead of `@noItemsMessage`). */
    noItemsMessage: [];
  };
}

interface SortOptions {
  isSorted?: boolean;
  isSortAscending?: boolean;
  onSort?: () => void;
  readOnly?: boolean;
}

interface HeaderModel {
  key: string;
  name?: string;
  nameTooltip?: EuiTableColumnNameTooltipProps;
  width?: string;
  minWidth?: string;
  maxWidth?: string;
  description?: string;
  mobileOptions?: TableMobileOptions;
  align: TableAlignment;
  testSubj?: string;
  sorting: SortOptions;
}

interface CellModel<T extends object> {
  key: string;
  column: EuiBasicTableColumn<T>;
  isActions: boolean;
  content?: EuiTableContent;
  component?: EuiTableCellComponent<T>;
  value?: unknown;
  align?: TableAlignment;
  isExpander?: boolean;
  textOnly?: boolean;
  truncateText?: boolean;
  setScopeRow?: boolean;
  width?: string;
  minWidth?: string;
  maxWidth?: string;
  mobileOptions?: TableMobileOptions;
  mobileContent?: EuiTableContent;
  mobileComponent?: EuiTableCellComponent<T>;
  hasMobile?: boolean;
  attributes?: EuiTableElementProps;
  // actions cells
  actions?: Array<Action<T>>;
  collapsed?: boolean;
  hasActions?: boolean | 'custom';
}

interface RowModel<T extends object> {
  key: string;
  item: T;
  itemId: ItemIdResolved;
  rowIndex: number;
  displayedRowIndex: number;
  selected: boolean;
  isSelectable: boolean;
  checkbox?: {
    id: string;
    disabled: boolean;
    label: string;
    testSubj: string;
  };
  hasActions: boolean | 'custom';
  isExpandable: boolean;
  expandedRowId?: string;
  expandedValue?: unknown;
  expandedText?: EuiTableContent;
  expandedRowColSpan: number;
  rowAttributes: EuiTableElementProps;
  onClick?: (event: Event) => void;
  cells: CellModel<T>[];
}

/** Stable panelled factories per breakpoint (memoized by `useEuiBorealisStyles`). */
const PANELLED = new Map<unknown, ReturnType<typeof euiBasicTableWrapperPanelledStyles>>();
function panelledFactory(breakpoint: TableResponsiveBreakpoint | undefined) {
  let factory = PANELLED.get(breakpoint);
  if (!factory) {
    factory = euiBasicTableWrapperPanelledStyles(breakpoint as never);
    PANELLED.set(breakpoint, factory);
  }
  return factory;
}

const SAFARI_LOADING_WORKAROUND = htmlSafe('position: relative;');

export default class EuiBasicTable<T extends object = any> extends Component<
  EuiBasicTableSignature<T>
> {
  @service declare euiI18n: EuiI18n;

  tableId = `__table${randomId()}`;
  selectAllId = `_selection_column-checkbox${randomId()}`;

  /** Uncontrolled selection, `null` until the user (or `initialSelected`) sets it. */
  @tracked localSelection: T[] | null = null;

  get pageSize(): number {
    return this.args.pagination?.pageSize ?? PAGINATION_DEFAULTS.itemsPerPage;
  }

  get isSelectionControlled(): boolean {
    return !!this.args.selection?.selected;
  }

  /** Upstream `getDerivedStateFromProps` + `getInitialSelection`. */
  @cached
  get selectionState(): { selection: T[]; removed: boolean } {
    const { selection, itemId, items } = this.args;
    if (!selection) {
      return { selection: [], removed: false };
    }
    let unfiltered: T[];
    if (selection.selected) {
      unfiltered = selection.selected;
    } else if (this.localSelection) {
      unfiltered = this.localSelection;
    } else if (selection.initialSelected && items.length > 0) {
      unfiltered = selection.initialSelected;
    } else {
      unfiltered = [];
    }
    // Ensure we're not including selections that aren't in the
    // current `items` array (affected by pagination)
    const ids = new Set(items.map((item) => getItemId(item, itemId)));
    const filtered = unfiltered.filter((selected) =>
      ids.has(getItemId(selected, itemId))
    );
    return {
      selection: filtered,
      removed: filtered.length !== unfiltered.length
    };
  }

  get selection(): T[] {
    return this.selectionState.selection;
  }

  /** Reports selections dropped because their items left `@items`. */
  syncSelection = modifier(
    (_element: Element, [state]: [{ selection: T[]; removed: boolean }]) => {
      if (!state.removed) return;
      next(() => {
        if (this.isDestroying || this.isDestroyed) return;
        if (!this.isSelectionControlled) this.localSelection = state.selection;
        this.args.selection?.onSelectionChange?.(state.selection);
      });
    }
  );

  buildCriteria(): Criteria<T> {
    const criteria: Criteria<T> = {};
    if (this.args.pagination) {
      criteria.page = {
        index: this.args.pagination.pageIndex,
        size: this.pageSize
      };
    }
    if (this.args.sorting) {
      criteria.sort = this.args.sorting.sort;
    }
    return criteria;
  }

  changeSelection(changedSelection: T[]): void {
    const { selection } = this.args;
    if (!selection) return;
    selection.onSelectionChange?.(changedSelection);
    if (!this.isSelectionControlled) {
      this.localSelection = changedSelection;
    }
  }

  clearSelection(): void {
    this.changeSelection([]);
  }

  @action
  onPageSizeChange(size: number): void {
    this.clearSelection();
    const currentCriteria = this.buildCriteria();
    const criteria = {
      ...currentCriteria,
      // when page size changes, we take the user back to the first page
      page: { index: 0, size }
    };
    this.args.onChange?.(criteria);
  }

  @action
  onPageChange(index: number): void {
    this.clearSelection();
    const currentCriteria = this.buildCriteria();
    const criteria = {
      ...currentCriteria,
      page: { ...currentCriteria.page!, index }
    };
    this.args.onChange?.(criteria);
  }

  onColumnSortChange(column: EuiBasicTableColumn<T>): void {
    this.clearSelection();
    const currentCriteria = this.buildCriteria();
    const field = (column as EuiTableFieldDataColumnType<T>).field;
    let direction: 'asc' | 'desc' = SortDirection.ASC;
    if (
      currentCriteria.sort &&
      (currentCriteria.sort.field === field ||
        currentCriteria.sort.field === column.name)
    ) {
      direction = SortDirection.reverse(currentCriteria.sort.direction);
    }
    const criteria: Criteria<T> = {
      ...currentCriteria,
      // resetting the page if the criteria has one
      page: !currentCriteria.page
        ? undefined
        : { index: 0, size: currentCriteria.page.size },
      sort: { field: (field || column.name) as keyof T, direction }
    };
    this.args.onChange?.(criteria as Criteria<T> & CriteriaWithPagination<T>);
  }

  /** `enableAllColumns` makes field columns without `sortable` sortable. */
  withDefaultSortable(column: EuiBasicTableColumn<T>): EuiBasicTableColumn<T> {
    const { sorting } = this.args;
    if (
      sorting?.sort &&
      !!sorting.enableAllColumns &&
      (column as EuiTableFieldDataColumnType<T>).field &&
      (column as EuiTableFieldDataColumnType<T>).sortable == null
    ) {
      return { ...(column as EuiTableFieldDataColumnType<T>), sortable: true };
    }
    return column;
  }

  resolveColumnSortDirection(column: EuiBasicTableColumn<T>) {
    const { sorting } = this.args;
    const { sortable, field, name } = column as EuiTableFieldDataColumnType<T>;
    if (!sorting || !sorting.sort || !sortable) {
      return undefined;
    }
    if (sorting.sort.field === field || sorting.sort.field === name) {
      return sorting.sort.direction;
    }
    return undefined;
  }

  resolveColumnOnSort(column: EuiBasicTableColumn<T>) {
    const { sorting } = this.args;
    const { sortable, name } = column as EuiTableFieldDataColumnType<T>;
    if (!sorting || !sortable) {
      return undefined;
    }
    if (!this.args.onChange) {
      throw new Error(`BasicTable is configured to be sortable on column [${name}] but
          [onChange] is not configured. This callback must be implemented to handle the sort requests`);
    }
    return () => this.onColumnSortChange(column);
  }

  sortOptions(column: EuiBasicTableColumn<T>, readOnly?: boolean): SortOptions {
    const sortDirection = this.resolveColumnSortDirection(column);
    return {
      isSorted: !!sortDirection,
      isSortAscending: sortDirection ? SortDirection.isAsc(sortDirection) : undefined,
      onSort: this.resolveColumnOnSort(column),
      readOnly: this.args.sorting?.readOnly || readOnly
    };
  }

  @cached
  get headers(): HeaderModel[] {
    return this.args.columns.map((original, index) => {
      const {
        field,
        width,
        minWidth,
        maxWidth,
        name,
        nameTooltip,
        align,
        dataType,
        sortable,
        mobileOptions,
        readOnly,
        description
      } = original as EuiTableFieldDataColumnType<T>;

      const shared = {
        width,
        minWidth,
        maxWidth,
        nameTooltip,
        description,
        mobileOptions,
        name,
        align: align || getAlignForDataType(dataType)
      };

      // actions column
      if ((original as EuiTableActionsColumnType<T>).actions) {
        return { ...shared, key: `_actions_h_${index}`, align: 'right', sorting: {} };
      }

      // computed column: only sortable if its `sortable` is a function
      if (!field) {
        return {
          ...shared,
          key: `_computed_column_h_${index}`,
          testSubj: `tableHeaderCell_${typeof name === 'string' ? name : ''}_${index}`,
          sorting:
            this.args.sorting && typeof sortable === 'function'
              ? this.sortOptions(original, readOnly)
              : {}
        };
      }

      // field data column
      const column = this.withDefaultSortable(original);
      return {
        ...shared,
        key: `_data_h_${String(field)}_${index}`,
        testSubj: `tableHeaderCell_${String(field)}_${index}`,
        sorting:
          this.args.sorting && (column as EuiTableFieldDataColumnType<T>).sortable
            ? this.sortOptions(column, readOnly)
            : {}
      };
    });
  }

  @cached
  get mobileSortItems(): EuiTableSortMobileItemOption[] {
    const { columns, sorting } = this.args;
    if (!sorting) return [];
    const items: EuiTableSortMobileItemOption[] = [];
    columns.forEach((original, index) => {
      const column = this.withDefaultSortable(original) as EuiTableFieldDataColumnType<T>;
      if (!column.sortable || column.mobileOptions?.show === false) {
        return;
      }
      const sortDirection = this.resolveColumnSortDirection(column);
      items.push({
        name: column.name,
        key: `_data_s_${String(column.field)}_${index}`,
        onSort: this.resolveColumnOnSort(column),
        isSorted: !!sortDirection,
        isSortAscending: sortDirection ? SortDirection.isAsc(sortDirection) : undefined
      });
    });
    return items;
  }

  @cached
  get selectAll() {
    const { items, selection } = this.args;
    if (!selection) return undefined;
    const selectableItems = items.filter(
      (item) => !selection.selectable || selection.selectable(item)
    );
    const current = this.selection;
    const checked =
      selectableItems.length > 0 && current.length === selectableItems.length;
    const indeterminate =
      !checked && selectableItems.length > 0 && current.length > 0;
    const selectAllRows = this.euiI18n.lookupToken(
      'euiBasicTable.selectAllRows',
      'Select all rows'
    );
    const deselectRows = this.euiI18n.lookupToken(
      'euiBasicTable.deselectRows',
      'Deselect rows'
    );
    return {
      selectableItems,
      checked,
      indeterminate,
      disabled: selectableItems.length === 0,
      label: checked || indeterminate ? deselectRows : selectAllRows,
      mobileLabel: selectAllRows
    };
  }

  @action
  onSelectAllChange(event: Event): void {
    const state = this.selectAll;
    const input = event.target as HTMLInputElement;
    if (!state) return;
    if (input.checked && !state.indeterminate) {
      this.changeSelection(state.selectableItems);
    } else {
      this.changeSelection([]);
    }
    // like React's controlled inputs, the box shows the resulting state
    input.checked = Boolean(this.selectAll?.checked);
    input.indeterminate = Boolean(this.selectAll?.indeterminate);
  }

  @action
  onRowSelectionChange(row: RowModel<T>, event: Event): void {
    const input = event.target as HTMLInputElement;
    const { itemId } = this.args;
    if (input.checked) {
      this.changeSelection([...this.selection, row.item]);
    } else {
      this.changeSelection(
        this.selection.filter(
          (selected) => getItemId(selected, itemId) !== row.itemId
        )
      );
    }
    // like React's controlled inputs, the box shows the resulting state
    input.checked = this.selection.some(
      (selected) => getItemId(selected, itemId) === row.itemId
    );
  }

  get hasPagination(): boolean {
    return !!this.args.pagination;
  }

  @cached
  get rows(): RowModel<T>[] {
    const {
      items,
      columns,
      selection,
      rowHeader,
      itemIdToExpandedRowMap,
      itemId: itemIdCallback
    } = this.args;
    const selected = this.selection;
    const allDisabled = selected.length > 0;

    // Occupy full width of table, taking checkbox & mobile only columns into account.
    const mobileOnlyCols = columns.filter(
      (column) => (column as EuiTableFieldDataColumnType<T>)?.mobileOptions?.only
    ).length;
    const expandedRowColSpan =
      (selection ? columns.length + 1 : columns.length) - mobileOnlyCols;

    return items.map((item, index) => {
      // with pagination the item's index is its position in the whole dataset
      const rowIndex =
        this.hasPagination && this.pageSize > 0
          ? this.args.pagination!.pageIndex * this.pageSize + index
          : index;
      const resolvedId = getItemId(item, itemIdCallback);
      const itemId: ItemIdResolved = resolvedId != null ? resolvedId : rowIndex;
      const isSelected = !selection
        ? false
        : !!selected.find(
            (selectedItem) => getItemId(selectedItem, itemIdCallback) === itemId
          );

      let checkbox: RowModel<T>['checkbox'];
      let rowSelectionDisabled = false;
      if (selection) {
        const disabled = !!(selection.selectable && !selection.selectable(item));
        const title = selection.selectableMessage?.(!disabled, item);
        checkbox = {
          id: `${this.tableId}_selection_column_${itemId}-checkbox`,
          disabled,
          label:
            title ||
            this.euiI18n.lookupToken('euiBasicTable.selectThisRow', 'Select row {index}', {
              index: index + 1
            }),
          testSubj: `checkboxSelectRow-${itemId}`
        };
        rowSelectionDisabled = disabled;
      }

      let hasActions: boolean | 'custom' = false;
      const cells = columns.map((column, columnIndex) =>
        this.cellModel(item, itemId, column, columnIndex, rowHeader, allDisabled)
      );
      cells.forEach((cell) => {
        if (cell.isActions) {
          // default action mobile row styles take precedence over custom
          hasActions = !hasActions && cell.hasActions === 'custom' ? 'custom' : true;
        }
      });

      const isExpandable = !!itemIdToExpandedRowMap &&
        Object.prototype.hasOwnProperty.call(itemIdToExpandedRowMap, itemId);
      const expandedValue = isExpandable ? itemIdToExpandedRowMap![itemId] : undefined;
      const { onClick, ...rowAttributes } = getRowProps(item, this.args.rowProps);

      return {
        key: `row_${itemId}`,
        item,
        itemId,
        rowIndex,
        displayedRowIndex: index,
        selected: isSelected,
        isSelectable: !rowSelectionDisabled,
        checkbox,
        hasActions,
        isExpandable,
        expandedRowId: isExpandable ? `row_${itemId}_expansion` : undefined,
        expandedValue,
        expandedText: isContent(expandedValue) ? expandedValue : undefined,
        expandedRowColSpan,
        rowAttributes,
        onClick: onClick as RowModel<T>['onClick'],
        cells
      };
    });
  }

  cellModel(
    item: T,
    itemId: ItemIdResolved,
    column: EuiBasicTableColumn<T>,
    columnIndex: number,
    rowHeader: string | undefined,
    allDisabled: boolean
  ): CellModel<T> {
    const actionsColumn = column as EuiTableActionsColumnType<T>;
    if (actionsColumn.actions) {
      const hasCustomActions = actionsColumn.actions.some(
        (action) => !!(action as { component?: unknown }).component
      );
      // Disable all actions if any row(s) are selected
      let actualActions = actionsColumn.actions.filter(
        (action) => !action.available || action.available(item)
      );
      let collapsed = false;
      if (actualActions.length > 2) {
        // if any of the actions `isPrimary`, add them inline as well, but only the first 2,
        // which we'll force to only show on hover for desktop views
        actualActions = allDisabled
          ? []
          : actualActions
              .filter((action) => action.isPrimary)
              .slice(0, 2)
              .map((action) => ({ ...action, showOnHover: true }) as Action<T>);
        // all the actions are in a popover
        collapsed = true;
      }
      return {
        key: `record_actions_${itemId}_${columnIndex}`,
        column,
        isActions: true,
        actions: actualActions,
        collapsed,
        hasActions: hasCustomActions ? 'custom' : true
      };
    }

    const fieldColumn = column as EuiTableFieldDataColumnType<T>;
    const { field, dataType } = fieldColumn;
    let content: EuiTableContent;
    let value: unknown;
    if (field) {
      value = get(item, field as string);
      if (!fieldColumn.component) {
        const renderer = fieldColumn.render || getRendererForDataType(dataType);
        content = renderer(value, item);
      }
    } else {
      const computed = column as EuiTableComputedColumnType<T>;
      if (!computed.component) {
        content = computed.render
          ? computed.render(item)
          : getRendererForDataType()(undefined);
      }
    }

    const {
      align,
      render,
      isExpander,
      textOnly,
      name,
      mobileOptions,
      truncateText,
      width,
      minWidth,
      maxWidth,
      className,
      component
    } = fieldColumn;
    const cellProps = getCellProps(item, column, this.args.cellProps);
    const mobileComponent = mobileOptions?.component;
    const mobileContent = mobileOptions?.render?.(item);
    return {
      key: field
        ? `_data_column_${String(field)}_${itemId}_${columnIndex}`
        : `_computed_column_${itemId}_${columnIndex}`,
      column,
      isActions: false,
      content,
      component,
      value,
      align: align || getAlignForDataType(dataType),
      isExpander,
      textOnly: textOnly || (!render && !component),
      truncateText,
      setScopeRow: !!field && field === rowHeader,
      width,
      minWidth,
      maxWidth,
      mobileOptions: { ...mobileOptions, header: mobileOptions?.header ?? name },
      mobileContent,
      mobileComponent,
      hasMobile: !!mobileComponent || mobileContent != null,
      attributes: {
        className,
        'data-test-subj': fieldColumn['data-test-subj'],
        ...cellProps
      }
    };
  }

  @cached
  get footers(): Array<{ key: string; align?: TableAlignment; content?: EuiTableContent }> | null {
    const { items, columns, pagination, selection } = this.args;
    const footers: Array<{ key: string; align?: TableAlignment; content?: EuiTableContent }> = [];
    let hasDefinedFooter = false;
    if (selection) {
      // an empty cell for the selection column
      footers.push({ key: '_selection_column_f' });
    }
    columns.forEach((column) => {
      const { mobileOptions, field, align, footer } =
        column as EuiTableFieldDataColumnType<T>;
      if (mobileOptions?.only) {
        return; // exclude columns that only exist for mobile headers
      }
      const content =
        typeof footer === 'function' ? footer({ items, pagination }) : footer;
      if (content) {
        footers.push({ key: `footer_${String(field)}_${footers.length - 1}`, align, content });
        hasDefinedFooter = true;
      } else {
        footers.push({ key: `footer_empty_${footers.length - 1}`, align });
      }
    });
    return footers.length && hasDefinedFooter ? footers : null;
  }

  get colSpan(): number {
    return this.args.columns.length + (this.args.selection ? 1 : 0);
  }

  get noItemsMessage(): string {
    return (
      this.args.noItemsMessage ??
      this.euiI18n.lookupToken('euiBasicTable.noItemsMessage', 'No items found')
    );
  }

  @cached
  get caption() {
    const { items, pagination, tableCaption } = this.args;
    const itemCount = items.length;
    const totalItemCount = pagination ? pagination.totalItemCount : itemCount;
    const page = pagination ? pagination.pageIndex + 1 : 1;
    const pageCount = pagination
      ? Math.ceil(pagination.totalItemCount / this.pageSize)
      : 1;
    return {
      tableName:
        tableCaption ||
        this.euiI18n.lookupToken('euiBasicTable.caption.tableName', 'Data table'),
      empty:
        itemCount === 0
          ? this.euiI18n.lookupToken('euiBasicTable.caption.emptyState', '(empty)')
          : undefined,
      itemCountPart:
        itemCount && pagination && totalItemCount > 0
          ? this.euiI18n.lookupToken(
              'euiBasicTable.caption.itemCountPart.withTotalItemCount',
              'Showing {itemCount} of {totalItemCount} data rows.',
              { itemCount, totalItemCount }
            )
          : undefined,
      paginationPart:
        pagination && pageCount > 1
          ? this.euiI18n.lookupToken(
              'euiBasicTable.caption.paginationPart.withPageCount',
              'Page {page} of {pageCount}.',
              { page, pageCount }
            )
          : undefined
    };
  }

  get paginationForBar(): Pagination {
    return this.args.pagination!;
  }

  get showPagination(): boolean {
    const { error, pagination } = this.args;
    if (!error && pagination && pagination.totalItemCount > 0) {
      if (!this.args.onChange) {
        throw new Error(`The Basic Table is configured with pagination but [onChange] is
        not configured. This callback must be implemented to handle pagination changes`);
      }
      return true;
    }
    return false;
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    return {
      caption: euiClass(context, euiTableCaptionStyles, euiScreenReaderOnlyCss()),
      body: this.args.loading
        ? euiClass(context, useEuiBorealisStyles(context, euiBasicTableBodyLoading))
        : undefined,
      panelled: this.args.panelled
        ? euiClass(
            context,
            useEuiBorealisStyles(context, panelledFactory(this.args.responsiveBreakpoint))
          )
        : undefined
    };
  }

  <template>
    <div
      class="euiBasicTable {{if @loading 'euiBasicTable-loading'}}"
      {{this.syncSelection this.selectionState}}
      ...attributes
    >
      {{#if @panelled}}
        <div
          class={{this.classes.panelled}}
          data-test-subj="euiBasicTablePanelledWrapper"
        >
          <BasicTableContent
            @table={{this}}
            @hasExpandedRowBlock={{flag @hasExpandedRowBlock (has-block "expandedRow")}}
            @hasNoItemsBlock={{flag @hasNoItemsBlock (has-block "noItemsMessage")}}
          >
            <:expandedRow as |item itemId value|>{{yield item itemId value to="expandedRow"}}</:expandedRow>
            <:noItemsMessage>{{yield to="noItemsMessage"}}</:noItemsMessage>
          </BasicTableContent>
        </div>
      {{else}}
        <BasicTableContent
          @table={{this}}
          @hasExpandedRowBlock={{flag @hasExpandedRowBlock (has-block "expandedRow")}}
          @hasNoItemsBlock={{flag @hasNoItemsBlock (has-block "noItemsMessage")}}
        >
          <:expandedRow as |item itemId value|>{{yield item itemId value to="expandedRow"}}</:expandedRow>
          <:noItemsMessage>{{yield to="noItemsMessage"}}</:noItemsMessage>
        </BasicTableContent>
      {{/if}}
      {{#if this.showPagination}}
        <PaginationBar
          @pagination={{this.paginationForBar}}
          @panelled={{@panelled}}
          @responsiveBreakpoint={{@responsiveBreakpoint}}
          @onPageSizeChange={{this.onPageSizeChange}}
          @onPageChange={{this.onPageChange}}
          @ariaControls={{this.tableId}}
        />
      {{/if}}
    </div>
  </template>
}

/** A forwarded block flag, or this component's own `has-block`. */
function flag(forwarded: boolean | undefined, own: boolean): boolean {
  return forwarded ?? own;
}

function isContent(value: unknown): value is EuiTableContent {
  return (
    typeof value === 'string' ||
    typeof value === 'number' ||
    (typeof value === 'object' && value !== null && 'toHTML' in value)
  );
}

function rowClick(onClick?: (event: Event) => void) {
  return onClick;
}

interface BasicTableContentSignature<T extends object> {
  Args: {
    table: EuiBasicTable<T>;
    hasExpandedRowBlock: boolean;
    hasNoItemsBlock: boolean;
  };
  Blocks: {
    expandedRow: [item: T, itemId: ItemIdResolved, value: unknown];
    noItemsMessage: [];
  };
}

/** The mobile header and the table (wrapped by the panelled look or not). */
class BasicTableContent<T extends object> extends Component<
  BasicTableContentSignature<T>
> {
  <template>
    {{#let @table as |t|}}
      <EuiTableHeaderMobile @responsiveBreakpoint={{t.args.responsiveBreakpoint}}>
        {{#if t.selectAll}}
          <EuiToolTip
            @content={{t.selectAll.label}}
            @display="block"
            @disableScreenReaderOutput={{true}}
          >
            <EuiCheckbox
              @id="{{t.selectAllId}}-mobile"
              @checked={{t.selectAll.checked}}
              @indeterminate={{t.selectAll.indeterminate}}
              @disabled={{t.selectAll.disabled}}
              @label={{t.selectAll.mobileLabel}}
              aria-label={{t.selectAll.label}}
              data-test-subj="checkboxSelectAll"
              {{on "change" t.onSelectAllChange}}
            />
          </EuiToolTip>
        {{/if}}
        {{#if t.mobileSortItems.length}}
          <EuiTableSortMobile @items={{t.mobileSortItems}} />
        {{/if}}
      </EuiTableHeaderMobile>
      <EuiTable
        id={{t.tableId}}
        @tableLayout={{if t.args.tableLayout t.args.tableLayout "fixed"}}
        @responsiveBreakpoint={{t.args.responsiveBreakpoint}}
        @compressed={{t.args.compressed}}
        @hasBackground={{t.args.hasBackground}}
        @scrollableInline={{t.args.scrollableInline}}
        style={{if t.args.loading SAFARI_LOADING_WORKAROUND}}
      >
        <caption class="euiTableCaption euiScreenReaderOnly {{t.classes.caption}}">
          <EuiDelayRender>
            <p>{{t.caption.tableName}}{{#if t.caption.empty}} {{t.caption.empty}}{{/if}},</p>
            {{#if t.args.items.length}}
              {{#if t.caption.itemCountPart}}<p>{{t.caption.itemCountPart}}</p>{{/if}}
            {{else}}
              {{#if @hasNoItemsBlock}}{{yield to="noItemsMessage"}},{{else}}{{t.noItemsMessage}},{{/if}}
            {{/if}}
            {{#if t.caption.paginationPart}}<p>{{t.caption.paginationPart}}</p>{{/if}}
          </EuiDelayRender>
        </caption>
        <EuiTableHeader>
          {{#if t.selectAll}}
            <EuiTableHeaderCellCheckbox>
              <EuiToolTip
                @content={{t.selectAll.label}}
                @display="block"
                @disableScreenReaderOutput={{true}}
              >
                <EuiCheckbox
                  @id={{t.selectAllId}}
                  @checked={{t.selectAll.checked}}
                  @indeterminate={{t.selectAll.indeterminate}}
                  @disabled={{t.selectAll.disabled}}
                  aria-label={{t.selectAll.label}}
                  data-test-subj="checkboxSelectAll"
                  {{on "change" t.onSelectAllChange}}
                />
              </EuiToolTip>
            </EuiTableHeaderCellCheckbox>
          {{/if}}
          {{#each t.headers key="key" as |header|}}
            <EuiTableHeaderCell
              @width={{header.width}}
              @minWidth={{header.minWidth}}
              @maxWidth={{header.maxWidth}}
              @description={{header.description}}
              @mobileOptions={{header.mobileOptions}}
              @align={{header.align}}
              @isSorted={{header.sorting.isSorted}}
              @isSortAscending={{header.sorting.isSortAscending}}
              @onSort={{header.sorting.onSort}}
              @readOnly={{header.sorting.readOnly}}
              data-test-subj={{header.testSubj}}
            >
              {{header.name}}
              {{#if header.nameTooltip}}
                <EuiIconTip
                  @content={{header.nameTooltip.content}}
                  @type={{if header.nameTooltip.icon header.nameTooltip.icon "question"}}
                  @position={{if header.nameTooltip.position header.nameTooltip.position "top"}}
                  @size="m"
                  @color="subdued"
                />
              {{/if}}
            </EuiTableHeaderCell>
          {{/each}}
        </EuiTableHeader>
        <EuiTableBody class={{t.classes.body}}>
          {{#if t.args.error}}
            <EuiTableRow>
              <EuiTableRowCell @align="center" colspan={{t.colSpan}} @mobileOptions={{FULL_WIDTH}}>
                <EuiIcon @type="minusCircle" @color="danger" aria-hidden="true" />
                {{t.args.error}}
              </EuiTableRowCell>
            </EuiTableRow>
          {{else if t.args.items.length}}
            {{#each t.rows key="key" as |row|}}
              <EuiTableRow
                aria-owns={{row.expandedRowId}}
                @hasSelection={{if t.args.selection true false}}
                @isSelectable={{row.isSelectable}}
                @isSelected={{row.selected}}
                @hasActions={{row.hasActions}}
                @isExpandable={{row.isExpandable}}
                @onClick={{rowClick row.onClick}}
                {{elementProps row.rowAttributes}}
              >
                {{#if row.checkbox}}
                  <EuiTableRowCellCheckbox>
                    <EuiToolTip
                      @content={{row.checkbox.label}}
                      @display="block"
                      @disableScreenReaderOutput={{true}}
                    >
                      <EuiCheckbox
                        @id={{row.checkbox.id}}
                        @disabled={{row.checkbox.disabled}}
                        @checked={{row.selected}}
                        aria-label={{row.checkbox.label}}
                        data-test-subj={{row.checkbox.testSubj}}
                        {{on "change" (fn t.onRowSelectionChange row)}}
                      />
                    </EuiToolTip>
                  </EuiTableRowCellCheckbox>
                {{/if}}
                {{#each row.cells key="key" as |cell|}}
                  {{#if cell.isActions}}
                    <EuiTableRowCell
                      @align="right"
                      @textOnly={{false}}
                      @hasActions={{cell.hasActions}}
                    >
                      <ExpandedItemActions
                        @actions={{actionsOrEmpty cell.actions}}
                        @actionsDisabled={{isTrue t.selection.length}}
                        @itemId={{row.itemId}}
                        @item={{row.item}}
                      />
                      {{#if cell.collapsed}}
                        <div>
                          <CollapsedItemActions
                            @actions={{actionsOf cell.column}}
                            @actionsDisabled={{isTrue t.selection.length}}
                            @itemId={{row.itemId}}
                            @item={{row.item}}
                            @displayedRowIndex={{row.rowIndex}}
                          />
                        </div>
                      {{/if}}
                    </EuiTableRowCell>
                  {{else if cell.hasMobile}}
                    <EuiTableRowCell
                      @align={{cell.align}}
                      @isExpander={{cell.isExpander}}
                      @textOnly={{cell.textOnly}}
                      @truncateText={{cell.truncateText}}
                      @setScopeRow={{cell.setScopeRow}}
                      @width={{cell.width}}
                      @minWidth={{cell.minWidth}}
                      @maxWidth={{cell.maxWidth}}
                      @mobileOptions={{cell.mobileOptions}}
                      {{elementProps cell.attributes}}
                    >
                      <:default>
                        {{#if cell.component}}
                          <cell.component @item={{row.item}} @value={{cell.value}} @column={{cell.column}} />
                        {{else}}
                          {{cell.content}}
                        {{/if}}
                      </:default>
                      <:mobile>
                        {{#if cell.mobileComponent}}
                          <cell.mobileComponent @item={{row.item}} @value={{cell.value}} @column={{cell.column}} />
                        {{else}}
                          {{cell.mobileContent}}
                        {{/if}}
                      </:mobile>
                    </EuiTableRowCell>
                  {{else}}
                    <EuiTableRowCell
                      @align={{cell.align}}
                      @isExpander={{cell.isExpander}}
                      @textOnly={{cell.textOnly}}
                      @truncateText={{cell.truncateText}}
                      @setScopeRow={{cell.setScopeRow}}
                      @width={{cell.width}}
                      @minWidth={{cell.minWidth}}
                      @maxWidth={{cell.maxWidth}}
                      @mobileOptions={{cell.mobileOptions}}
                      {{elementProps cell.attributes}}
                    >
                      {{#if cell.component}}
                        <cell.component @item={{row.item}} @value={{cell.value}} @column={{cell.column}} />
                      {{else}}
                        {{cell.content}}
                      {{/if}}
                    </EuiTableRowCell>
                  {{/if}}
                {{/each}}
              </EuiTableRow>
              {{#if row.isExpandable}}
                <EuiTableRow
                  id={{row.expandedRowId}}
                  @isExpandedRow={{true}}
                  @hasSelection={{if t.args.selection true false}}
                >
                  <EuiTableRowCell colspan={{row.expandedRowColSpan}} @textOnly={{false}}>
                    {{#if @hasExpandedRowBlock}}
                      {{yield row.item row.itemId row.expandedValue to="expandedRow"}}
                    {{else}}
                      {{row.expandedText}}
                    {{/if}}
                  </EuiTableRowCell>
                </EuiTableRow>
              {{/if}}
            {{/each}}
          {{else}}
            <EuiTableRow>
              <EuiTableRowCell @align="center" colspan={{t.colSpan}} @mobileOptions={{FULL_WIDTH}}>
                {{#if @hasNoItemsBlock}}
                  {{yield to="noItemsMessage"}}
                {{else}}
                  {{t.noItemsMessage}}
                {{/if}}
              </EuiTableRowCell>
            </EuiTableRow>
          {{/if}}
        </EuiTableBody>
        {{#if t.footers}}
          <EuiTableFooter>
            {{#each t.footers key="key" as |footer|}}
              <EuiTableFooterCell @align={{footer.align}}>{{footer.content}}</EuiTableFooterCell>
            {{/each}}
          </EuiTableFooter>
        {{/if}}
      </EuiTable>
    {{/let}}
  </template>
}

const FULL_WIDTH = { width: '100%' };

function actionsOrEmpty<T extends object>(actions?: Array<Action<T>>): Array<Action<T>> {
  return actions ?? [];
}

function isTrue(value: unknown): boolean {
  return Boolean(value);
}

function actionsOf<T extends object>(column: EuiBasicTableColumn<T>): Array<Action<T>> {
  return (column as EuiTableActionsColumnType<T>).actions;
}

