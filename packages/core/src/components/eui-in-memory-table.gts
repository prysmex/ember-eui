import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { Query } from '../utils/eui/search-bar/query.ts';
import { Comparators } from '../utils/eui/sort.ts';
import EuiBasicTable from './eui-basic-table.gts';
import EuiBasicTablePanel, {
  useEuiBasicTablePanelProps
} from './eui-basic-table-panel.gts';
import { PAGINATION_DEFAULTS } from './eui-basic-table/pagination-bar.gts';
import EuiSearchBar from './eui-search-bar.gts';
import EuiSearchBox from './eui-search-bar/eui-search-box.gts';
import EuiSpacer from './eui-spacer.gts';

import type {
  Criteria,
  EuiBasicTableColumn,
  EuiTableDataType,
  EuiTableFieldDataColumnType,
  EuiTableSortingType,
  Pagination as PaginationBarType
} from '../-private/basic-table.ts';
import type { Direction, PropertySort } from '../utils/eui/sort.ts';
import type { EuiBasicTableSignature } from './eui-basic-table.gts';
import type { EuiBasicTablePanelProps } from './eui-basic-table-panel.gts';
import type {
  EuiSearchBarOnChangeArgs,
  EuiSearchBarSignature,
  SchemaType
} from './eui-search-bar.gts';
import type Owner from '@ember/owner';

/** The search bar options (`EuiSearchBar` args). */
export type EuiInMemoryTableSearch = Omit<
  EuiSearchBarSignature['Args'],
  'onChange'
> & {
  /**
   * Called with `{ query, queryText, error }`; return `true` to also
   * filter the items in memory.
   */
  onChange?: (args: EuiSearchBarOnChangeArgs) => boolean | void;
};

export type Search = boolean | EuiInMemoryTableSearch;

export interface PaginationOptions {
  pageSizeOptions?: number[];
  initialPageIndex?: number;
  initialPageSize?: number;
  /** Controlled page index. */
  pageIndex?: number;
  /** Controlled page size. */
  pageSize?: number;
  showPerPageOptions?: boolean;
}

interface SortingOptions {
  sort: PropertySort;
}

type Sorting = boolean | SortingOptions;

/**
 * An `EuiBasicTable` that owns its state: it filters `@items` with an
 * optional `EuiSearchBar`, sorts them by the clicked column and pages
 * them in memory.
 */
export interface EuiInMemoryTableSignature<T extends object> {
  Element: HTMLDivElement;
  Args: Omit<
    EuiBasicTableSignature<T>['Args'],
    'pagination' | 'sorting' | 'onChange'
  > & {
    /**
     * Search bar: `true` for defaults, or `EuiSearchBar` args (`box`,
     * `filters`, `query`, `defaultQuery`, `onChange`, …). `box.schema:
     * true` derives the schema from the columns.
     */
    search?: Search;
    /**
     * `'eql'` (search syntax and filters) or `'text'` (plain text search,
     * filters ignored). Defaults to `'eql'`.
     */
    searchFormat?: 'eql' | 'text';
    /**
     * `true` or `{ pageSizeOptions, initialPageIndex, initialPageSize,
     * pageIndex, pageSize, showPerPageOptions }`.
     */
    pagination?: boolean | PaginationOptions;
    /** `true`, or `{ sort: { field, direction } }` for the initial sort. */
    sorting?: Sorting;
    /** Clicking a descending column unsorts it. Defaults to `true`. */
    allowNeutralSort?: boolean;
    /**
     * Informational: called with the new `{ page, sort }` criteria (the
     * table already manages that state).
     */
    onTableChange?: (nextValues: Criteria<T>) => void;
    /** Options of the in-memory query execution. */
    executeQueryOptions?: {
      defaultFields?: string[];
      isClauseMatcher?: (...args: any) => boolean;
      explain?: boolean;
      /** `false` skips executing the query (items are already filtered). */
      enabled?: boolean;
    };
  };
  Blocks: EuiBasicTableSignature<T>['Blocks'] & {
    /**
     * Content between the search bar and the table (only with `@search`,
     * as upstream). Yields `EuiBasicTablePanel` and the
     * `useEuiBasicTablePanelProps()` result, to build supporting panels
     * for a `@panelled` table.
     */
    childrenBetween: [
      Panel: typeof EuiBasicTablePanel,
      panelProps: EuiBasicTablePanelProps
    ];
    /** Search bar tools on the left. */
    toolsLeft: [];
    /** Search bar tools on the right. */
    toolsRight: [];
    /** The search bar's hint content. */
    hint: [];
  };
}

interface State<T extends object> {
  prevProps: {
    items: T[];
    sortName: unknown;
    sortDirection?: Direction;
    search?: Search;
    searchQuery?: Query | string;
  };
  query: Query | string | null;
  pageIndex: number;
  pageSize?: number;
  pageSizeOptions?: number[];
  sortName: unknown;
  sortDirection?: Direction;
  allowNeutralSort: boolean;
  showPerPageOptions: boolean | undefined;
}

function isSearchBarProps(search: Search | undefined): search is EuiInMemoryTableSearch {
  return typeof search !== 'boolean';
}

/** Upstream `getQueryFromSearch`. */
const getQueryFromSearch = (
  search: Search | undefined,
  defaultQuery: boolean,
  searchFormat: 'eql' | 'text'
): Query | string => {
  if (!search) {
    return searchFormat === 'text' ? '""' : '';
  }
  const searchProps = search as EuiInMemoryTableSearch;
  const queryString = defaultQuery
    ? (searchProps.defaultQuery ?? searchProps.query ?? '')
    : (searchProps.query ?? '');

  if (searchFormat === 'text') {
    return `"${String(queryString as string)}"`;
  }
  return typeof queryString === 'string' ? Query.parse(queryString) : queryString;
};

const getInitialPagination = (pagination: boolean | PaginationOptions | undefined) => {
  if (!pagination) {
    return { pageIndex: undefined, pageSize: undefined };
  }
  const defaults = PAGINATION_DEFAULTS;
  const {
    pageSizeOptions = defaults.itemsPerPageOptions,
    showPerPageOptions = defaults.showPerPageOptions
  } = pagination as PaginationOptions;

  const defaultPageSize = pageSizeOptions?.includes(defaults.itemsPerPage)
    ? defaults.itemsPerPage
    : pageSizeOptions[0];

  const initialPageIndex =
    pagination === true
      ? 0
      : (pagination.pageIndex ?? pagination.initialPageIndex ?? 0);
  const initialPageSize =
    pagination === true
      ? defaultPageSize
      : (pagination.pageSize ?? pagination.initialPageSize ?? defaultPageSize);

  if (
    showPerPageOptions &&
    initialPageSize != null &&
    !pageSizeOptions?.includes(initialPageSize)
  ) {
    throw new Error(
      `EuiInMemoryTable received initialPageSize ${initialPageSize}, which wasn't provided within pageSizeOptions.`
    );
  }

  return {
    pageIndex: initialPageIndex,
    pageSize: initialPageSize,
    pageSizeOptions,
    showPerPageOptions
  };
};

function findColumnByProp<T extends object>(
  columns: Array<EuiBasicTableColumn<T>>,
  prop: 'field' | 'name',
  value: unknown
) {
  for (const column of columns) {
    if ((column as Record<string, unknown>)[prop] === value) {
      return column;
    }
  }
  return undefined;
}

function findColumnByFieldOrName<T extends object>(
  columns: Array<EuiBasicTableColumn<T>>,
  value: unknown
) {
  // The passed value can be a column's `field` or its `name`
  // for backwards compatibility `field` must be checked first
  let column = findColumnByProp(columns, 'field', value);
  if (column == null) {
    column = findColumnByProp(columns, 'name', value);
  }
  return column;
}

function getInitialSorting<T extends object>(
  columns: Array<EuiBasicTableColumn<T>>,
  sorting: Sorting | undefined
): { sortName: unknown; sortDirection?: Direction } {
  if (!sorting || !(sorting as SortingOptions).sort) {
    return { sortName: undefined, sortDirection: undefined };
  }
  const { field: sortable, direction: sortDirection } = (sorting as SortingOptions).sort;
  const sortColumn = findColumnByFieldOrName(columns, sortable);
  if (sortColumn == null) {
    return { sortName: undefined, sortDirection: undefined };
  }
  return { sortName: sortColumn.name, sortDirection };
}

export default class EuiInMemoryTable<T extends object = any> extends Component<
  EuiInMemoryTableSignature<T>
> {
  private _state: State<T>;
  @tracked private stateVersion = 0;

  constructor(owner: Owner, args: EuiInMemoryTableSignature<T>['Args']) {
    super(owner, args);
    const { columns, search, pagination, sorting, allowNeutralSort } = args;
    const { pageIndex, pageSize, pageSizeOptions, showPerPageOptions } =
      getInitialPagination(pagination);
    const { sortName, sortDirection } = getInitialSorting(columns, sorting);
    this._state = {
      prevProps: {
        items: args.items,
        sortName,
        sortDirection,
        search,
        searchQuery: search ? (search as EuiInMemoryTableSearch).query : ''
      },
      query: getQueryFromSearch(search, true, args.searchFormat ?? 'eql'),
      pageIndex: pageIndex || 0,
      pageSize,
      pageSizeOptions,
      sortName,
      sortDirection,
      allowNeutralSort: allowNeutralSort !== false,
      showPerPageOptions
    };
  }

  get searchFormat(): 'eql' | 'text' {
    return this.args.searchFormat ?? 'eql';
  }

  /**
   * Upstream `getDerivedStateFromProps`, applied whenever the state is
   * read; the untracked state it updates is only read through here.
   */
  get state(): State<T> {
    void this.stateVersion;
    this.deriveStateFromArgs();
    return this._state;
  }

  private deriveStateFromArgs(): void {
    const prevState = this._state;
    const { items, pagination, columns, sorting, search } = this.args;
    let updated = prevState;
    if (items !== prevState.prevProps.items) {
      // We have new items because an external search has completed, so reset pagination state.
      let nextPageIndex = 0;
      if (pagination != null && typeof pagination !== 'boolean') {
        nextPageIndex = pagination.pageIndex || 0;
      }
      updated = {
        ...updated,
        prevProps: { ...updated.prevProps, items },
        pageIndex: nextPageIndex
      };
    }

    // apply changes to controlled pagination
    if (pagination != null && typeof pagination !== 'boolean') {
      if (pagination.pageSize != null && pagination.pageSize !== updated.pageSize) {
        updated = { ...updated, pageSize: pagination.pageSize };
      }
      if (pagination.pageIndex != null && pagination.pageIndex !== updated.pageIndex) {
        updated = { ...updated, pageIndex: pagination.pageIndex };
      }
    }

    const { sortName, sortDirection } = getInitialSorting(columns, sorting);
    if (
      sortName !== prevState.prevProps.sortName ||
      sortDirection !== prevState.prevProps.sortDirection
    ) {
      updated = {
        ...updated,
        prevProps: { ...updated.prevProps, sortName, sortDirection },
        sortName,
        sortDirection
      };
    }

    // Ember: the previous `search.query` value is kept (not only the
    // `search` object), so a mutated or getter-backed config also works
    const nextQuery = search ? (search as EuiInMemoryTableSearch).query : '';
    const prevQuery = prevState.prevProps.searchQuery;
    if (nextQuery !== prevQuery) {
      updated = {
        ...updated,
        prevProps: { ...updated.prevProps, search, searchQuery: nextQuery },
        query: getQueryFromSearch(search, false, this.searchFormat)
      };
    }
    if (updated !== prevState) {
      this._state = updated;
    }
  }

  setState(changes: Partial<State<T>>): void {
    this._state = { ...this.state, ...changes };
    this.stateVersion++;
  }

  @action
  onTableChange({ page, sort }: Criteria<T>): void {
    let { index: pageIndex, size: pageSize } = (page || {}) as {
      index: number;
      size: number;
    };

    // don't apply pagination changes that are otherwise controlled
    // `page` is left unchanged as it goes to the consumer's `onTableChange` callback, allowing the app to respond
    const { pagination } = this.args;
    if (pagination != null && typeof pagination !== 'boolean') {
      if (pagination.pageSize != null) pageSize = pagination.pageSize;
      if (pagination.pageIndex != null) pageIndex = pagination.pageIndex;
    }

    let { field: sortName, direction: sortDirection } = (sort || {}) as {
      field: unknown;
      direction: Direction;
    };

    // To keep backwards compatibility reportedSortName needs to be tracked separately
    // from sortName; sortName gets stored internally while reportedSortName is sent to the callback
    let reportedSortName = sortName;

    // EuiBasicTable returns the column's `field` instead of `name` on sort
    // and the column's `name` instead of `field` on pagination
    if (sortName) {
      const sortColumn = findColumnByFieldOrName(this.args.columns, sortName);
      if (sortColumn) {
        // Ensure sortName uses `name`
        sortName = sortColumn.name;
        // Ensure reportedSortName uses `field` if it exists
        const sortField = (sortColumn as EuiTableFieldDataColumnType<T>).field;
        if (sortField) reportedSortName = sortField;
      }
    }

    const state = this.state;
    // Allow going back to 'neutral' sorting
    if (
      state.allowNeutralSort &&
      state.sortName === sortName &&
      state.sortDirection === 'desc' &&
      sortDirection === 'asc'
    ) {
      sortName = '';
      reportedSortName = '';
      sortDirection = 'asc'; // Default sort direction.
    }

    this.args.onTableChange?.({
      page,
      sort: { field: reportedSortName as keyof T, direction: sortDirection }
    });

    this.setState({ pageIndex, pageSize, sortName, sortDirection });
  }

  @action
  onQueryChange({ query, queryText, error }: EuiSearchBarOnChangeArgs): void {
    const { search } = this.args;
    if (isSearchBarProps(search)) {
      if (search.onChange) {
        const shouldQueryInMemory =
          error == null
            ? search.onChange({ query: query!, queryText, error: null })
            : search.onChange({ query: null, queryText, error });
        if (!shouldQueryInMemory) {
          return;
        }
      }
    }
    // Reset pagination state.
    this.setState({
      prevProps: {
        ...this.state.prevProps,
        search,
        searchQuery: search ? (search as EuiInMemoryTableSearch).query : ''
      },
      query,
      pageIndex: 0
    });
  }

  /**
   * Alternative to onQueryChange - allows consumers to specify they want the
   * search bar to ignore EQL syntax and only use the searchbar for plain text
   */
  @action
  onPlainTextSearch(searchValue: string): void {
    const escapedQueryText = searchValue.replace(/["\\]/g, '\\$&');
    const { search } = this.args;
    if (isSearchBarProps(search)) {
      if (search.onChange) {
        const shouldQueryInMemory = search.onChange({
          query: null,
          queryText: escapedQueryText,
          error: null
        });
        if (!shouldQueryInMemory) {
          return;
        }
      }
    }
    this.setState({ query: `"${escapedQueryText}"` });
  }

  resolveSearchSchema(): SchemaType {
    return this.args.columns.reduce<{
      strict: boolean;
      fields: Record<string, { type: EuiTableDataType }>;
    }>(
      (schema, column) => {
        const { field, dataType } = column as EuiTableFieldDataColumnType<T>;
        if (field) {
          schema.fields[field as string] = { type: dataType || 'string' };
        }
        return schema;
      },
      { strict: true, fields: {} }
    );
  }

  /** The `EuiSearchBar` args (eql format). */
  @cached
  get searchBarArgs(): EuiInMemoryTableSearch {
    const { search } = this.args;
    if (!isSearchBarProps(search)) return {};
    const args = { ...search };
    if (args.box && args.box.schema === true) {
      args.box = { ...args.box, schema: this.resolveSearchSchema() };
    }
    return args;
  }

  /** The plain text search field (text format). */
  get textSearch() {
    const search = this.args.search;
    const { box = {}, query, defaultQuery } = (
      isSearchBarProps(search) ? search : {}
    ) as EuiInMemoryTableSearch;
    // `schema` is not a field option
    const { schema: _schema, ...searchBoxProps } = box;
    // use only string values, ignore Query objects
    const displayQuery =
      typeof query === 'string'
        ? query
        : typeof defaultQuery === 'string'
          ? defaultQuery
          : '';
    return { box: searchBoxProps, query: displayQuery };
  }

  getItemSorter(): (a: T, b: T) => number {
    const { sortName, sortDirection } = this.state;
    const sortColumn = this.args.columns.find(
      ({ name }) => name === sortName
    ) as EuiTableFieldDataColumnType<T> | undefined;

    if (sortColumn == null) {
      // can't return a non-function so return a function that says everything is the same
      return () => 0;
    }

    const sortable = sortColumn.sortable;
    if (typeof sortable === 'function') {
      return Comparators.value(sortable, Comparators.default(sortDirection));
    }
    return Comparators.property(
      sortColumn.field as string,
      Comparators.default(sortDirection)
    );
  }

  @cached
  get visible(): { items: T[]; totalItemCount: number } {
    const { executeQueryOptions } = this.args;
    const state = this.state;
    const { items } = state.prevProps;

    if (!items.length) {
      return { items: [], totalItemCount: 0 };
    }

    const { query, sortName, pageIndex, pageSize } = state;

    const matchingItems =
      query !== null && executeQueryOptions?.enabled !== false
        ? Query.execute(query, items, executeQueryOptions)
        : items;

    const sortedItems = sortName
      ? matchingItems
          .slice(0) // avoid mutating the source array
          .sort(this.getItemSorter()) // sort, causes mutation
      : matchingItems;

    let visibleItems = sortedItems;
    if (pageSize && this.args.pagination) {
      const startIndex = pageIndex * pageSize;
      visibleItems = sortedItems.slice(
        startIndex,
        Math.min(startIndex + pageSize, sortedItems.length)
      );
    }

    return { items: visibleItems, totalItemCount: matchingItems.length };
  }

  @cached
  get pagination(): PaginationBarType | undefined {
    if (!this.args.pagination) return undefined;
    const { pageIndex, pageSize, pageSizeOptions, showPerPageOptions } = this.state;
    return {
      pageIndex,
      pageSize: pageSize ?? 1,
      pageSizeOptions,
      totalItemCount: this.visible.totalItemCount,
      showPerPageOptions
    };
  }

  /**
   * Data loaded from a server can have a default sort order which is meaningful to the
   * user, but can't be reproduced with client-side sort logic. So we allow the table to display
   * rows in the order in which they're initially loaded by providing an undefined sorting prop.
   */
  @cached
  get sorting(): EuiTableSortingType<T> | undefined {
    if (!this.args.sorting) return undefined;
    const { sortName, sortDirection, allowNeutralSort } = this.state;
    return {
      sort:
        !sortName && !sortDirection
          ? undefined
          : { field: sortName as keyof T, direction: sortDirection as Direction },
      allowNeutralSort
    };
  }

  <template>
    {{#let
      (component
        EuiBasicTable
        items=this.visible.items
        itemId=@itemId
        rowProps=@rowProps
        cellProps=@cellProps
        columns=@columns
        pagination=this.pagination
        sorting=this.sorting
        selection=@selection
        onChange=this.onTableChange
        error=@error
        loading=@loading
        noItemsMessage=@noItemsMessage
        tableLayout=@tableLayout
        compressed=@compressed
        itemIdToExpandedRowMap=@itemIdToExpandedRowMap
        tableCaption=@tableCaption
        rowHeader=@rowHeader
        panelled=@panelled
        responsiveBreakpoint=@responsiveBreakpoint
        hasBackground=@hasBackground
        scrollableInline=@scrollableInline
        stickyHeader=@stickyHeader
        stickyScrollbar=@stickyScrollbar
        css=@css
        hasExpandedRowBlock=(has-block "expandedRow")
        hasNoItemsBlock=(has-block "noItemsMessage")
      )
      as |Table|
    }}
      {{#if @search}}
        <div>
          {{#if (isText this.searchFormat)}}
            <EuiSearchBox
              @box={{this.textSearch.box}}
              @query={{this.textSearch.query}}
              @onSearch={{this.onPlainTextSearch}}
            />
          {{else}}
            <EuiSearchBar
              @onChange={{this.onQueryChange}}
              @defaultQuery={{this.searchBarArgs.defaultQuery}}
              @query={{this.searchBarArgs.query}}
              @box={{this.searchBarArgs.box}}
              @filters={{this.searchBarArgs.filters}}
              @dateFormat={{this.searchBarArgs.dateFormat}}
              @hint={{this.searchBarArgs.hint}}
              @compressed={{this.searchBarArgs.compressed}}
              @showErrorTooltip={{this.searchBarArgs.showErrorTooltip}}
              @hasToolsLeftBlock={{has-block "toolsLeft"}}
              @hasToolsRightBlock={{has-block "toolsRight"}}
              @hasHintBlock={{has-block "hint"}}
            >
              <:toolsLeft>{{yield to="toolsLeft"}}</:toolsLeft>
              <:toolsRight>{{yield to="toolsRight"}}</:toolsRight>
              <:hint>{{yield to="hint"}}</:hint>
            </EuiSearchBar>
          {{/if}}
          <EuiSpacer @size="l" />
          {{yield EuiBasicTablePanel PANEL_PROPS to="childrenBetween"}}
          <Table ...attributes>
            <:expandedRow as |item itemId value|>{{yield item itemId value to="expandedRow"}}</:expandedRow>
            <:noItemsMessage>{{yield to="noItemsMessage"}}</:noItemsMessage>
          </Table>
        </div>
      {{else}}
        <Table ...attributes>
          <:expandedRow as |item itemId value|>{{yield item itemId value to="expandedRow"}}</:expandedRow>
          <:noItemsMessage>{{yield to="noItemsMessage"}}</:noItemsMessage>
        </Table>
      {{/if}}
    {{/let}}
  </template>
}

const PANEL_PROPS = useEuiBasicTablePanelProps();

function isText(format: string): boolean {
  return format === 'text';
}
