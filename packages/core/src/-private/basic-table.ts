/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

// Column, action, selection, sorting and pagination types of EuiBasicTable
// and EuiInMemoryTable (upstream EUI 123.1.0 `components/basic_table`
// `table_types.ts`, `action_types.ts`, `pagination_bar.tsx` and the
// helpers of `basic_table.tsx`), with Ember render hooks: React nodes
// become text (`string`, numbers or `htmlSafe` strings) or components.

import { modifier } from 'ember-modifier';

import {
  formatAuto,
  formatBoolean,
  formatDate,
  formatNumber,
  formatText
} from '../utils/eui/format.ts';

import type { TableAlignment, TableMobileOptions } from './table.ts';
import type { Primitive } from '../utils/eui/sort.ts';
import type { ComponentLike } from '@glint/template';
import type { SafeString } from '@ember/template';

/** Text content of a cell, footer or action (upstream React nodes). */
export type EuiTableContent = string | number | SafeString | null | undefined;

export type ItemId<T> = string | number | ((item: T) => string);
export type ItemIdResolved = string | number;

export type EuiTableDataType = 'auto' | 'string' | 'number' | 'boolean' | 'date';

export interface Pagination {
  /** The current page (zero-based) index. */
  pageIndex: number;
  /**
   * The maximum number of items that can be shown in a single page.
   * Pass `0` to display the selected "Show all" option and hide the pagination.
   * Defaults to `10`.
   */
  pageSize?: number;
  /** The total number of items the page is "sliced" of. */
  totalItemCount: number;
  /**
   * Configures the page size dropdown options. Pass `0` as one of the
   * options to create a "Show all" option. Defaults to `[10, 25, 50]`.
   */
  pageSizeOptions?: number[];
  /** Set to false to hide the page size dropdown. Defaults to `true`. */
  showPerPageOptions?: boolean;
}

export interface EuiTableFooterProps<T> {
  items: T[];
  pagination?: Pagination;
}

/** An icon with a tooltip next to a column name. */
export interface EuiTableColumnNameTooltipProps {
  /** The main content of the tooltip. */
  content: string;
  /** The icon type to display. Defaults to `'question'`. */
  icon?: string;
  /** Position of the tooltip. Defaults to `'top'`. */
  position?: 'top' | 'right' | 'bottom' | 'left';
}

/** Args of a cell `component`. */
export interface EuiTableCellComponentArgs<T> {
  /** The row's item. */
  item: T;
  /** The value of the column's `field` (field data columns). */
  value?: unknown;
  /** The column. */
  column: EuiBasicTableColumn<T & object>;
}

export type EuiTableCellComponent<T> = ComponentLike<{
  Args: EuiTableCellComponentArgs<T>;
}>;

/** Cards (mobile) options of a column. */
export type EuiTableColumnMobileOptions<T> = TableMobileOptions & {
  /** Text shown instead of the cell content in the cards layout. */
  render?: (item: T) => EuiTableContent;
  /** A component shown instead of the cell content in the cards layout. */
  component?: EuiTableCellComponent<T>;
};

interface ColumnBase {
  /** A description of the column (the header's title). */
  description?: string;
  /** Requested width, e.g. `'30%'` or `'120px'`. */
  width?: string;
  /** Requested min width (with `@tableLayout="auto"`). */
  minWidth?: string;
  /** Requested max width (with `@tableLayout="auto"`). */
  maxWidth?: string;
  /** Classes of the column's cells. */
  className?: string;
  /** `data-test-subj` of the column's cells. */
  'data-test-subj'?: string;
}

export interface EuiTableFieldDataColumnType<T> extends ColumnBase {
  /** A field of the item (may be a nested `outer.inner` path). */
  field: keyof T | (string & {});
  /** The display name of the column. */
  name: string;
  /** An icon with a tooltip next to the name. */
  nameTooltip?: EuiTableColumnNameTooltipProps;
  /** Rendering hint of the value: alignment and default format. */
  dataType?: EuiTableDataType;
  /**
   * The user can sort on this column; a function returns the value to sort
   * against.
   */
  sortable?: boolean | ((item: T) => Primitive);
  /** Shows the sort direction without letting the user change it. */
  readOnly?: boolean;
  /** Horizontal alignment. Defaults to `'left'` (`'right'` for numbers). */
  align?: TableAlignment;
  /** Wraps the content in a text span (word break / truncation). */
  textOnly?: boolean;
  /** Truncates overflowing text on one line. */
  truncateText?: boolean;
  /** Cards layout options. */
  mobileOptions?: EuiTableColumnMobileOptions<T>;
  /** Renders the cell as text from the field value and item. */
  render?: (value: any, item: T) => EuiTableContent;
  /** Renders the cell with a component (`@item`, `@value`, `@column`). */
  component?: EuiTableCellComponent<T>;
  /** Content of the footer below the column. */
  footer?: EuiTableContent | ((props: EuiTableFooterProps<T>) => EuiTableContent);
  /** The column holds the expand button of `@itemIdToExpandedRowMap`. */
  isExpander?: boolean;
}

export interface EuiTableComputedColumnType<T> extends ColumnBase {
  /** Renders the cell as text from the item. */
  render?: (item: T) => EuiTableContent;
  /** Renders the cell with a component (`@item`, `@column`). */
  component?: EuiTableCellComponent<T>;
  /** The display name of the column. */
  name?: string;
  /** An icon with a tooltip next to the name. */
  nameTooltip?: EuiTableColumnNameTooltipProps;
  /** Makes the column sortable: returns the value to sort against. */
  sortable?: (item: T) => Primitive;
  readOnly?: boolean;
  align?: TableAlignment;
  truncateText?: boolean;
  isExpander?: boolean;
  /** Cards layout options. */
  mobileOptions?: EuiTableColumnMobileOptions<T>;
  /** Ember: computed columns have no field. */
  field?: undefined;
  footer?: EuiTableContent | ((props: EuiTableFooterProps<T>) => EuiTableContent);
}

export interface EuiTableActionsColumnType<T extends object> {
  /** {@link DefaultItemAction}s or {@link CustomItemAction}s. */
  actions: Array<Action<T>>;
  /** The display name of the column. */
  name?: string;
  nameTooltip?: EuiTableColumnNameTooltipProps;
  description?: string;
  width?: string;
  minWidth?: string;
  maxWidth?: string;
  /** Upstream beta; not supported by the Ember table yet. */
  sticky?: boolean;
}

export type EuiBasicTableColumn<T extends object> =
  | EuiTableFieldDataColumnType<T>
  | EuiTableComputedColumnType<T>
  | EuiTableActionsColumnType<T>;

type ButtonColor =
  | 'primary'
  | 'accent'
  | 'accentSecondary'
  | 'success'
  | 'warning'
  | 'danger'
  | 'text'
  | 'neutral'
  | 'risk';

export interface DefaultItemActionBase<T extends object> {
  /** The name (the text in the collapsed menu or of a button action). */
  name: string | ((item: T) => string);
  /** Describes the action (the tooltip). */
  description: string | ((item: T) => string);
  /** Called with the row's item and the click event. */
  onClick?: (item: T, event: MouseEvent) => void;
  href?: string | ((item: T) => string);
  target?: string;
  /** Whether the action is shown for the item. */
  available?: (item: T) => boolean;
  /** Whether the action is enabled for the item. */
  enabled?: (item: T) => boolean;
  'data-test-subj'?: string | ((item: T) => string);
  /**
   * With more than 2 actions, up to 2 primary actions show (on hover)
   * next to the menu of all actions.
   */
  isPrimary?: boolean;
  /** Shows the action only on row hover or keyboard focus. */
  showOnHover?: boolean;
}

export interface DefaultItemAction<T extends object>
  extends DefaultItemActionBase<T> {
  /** `'button'` (default, an `EuiButtonEmpty`) or `'icon'`. */
  type?: 'button' | 'icon';
  /** The icon (required for `type: 'icon'`). */
  icon?: string | ((item: T) => string);
  /** Defaults to `'text'`. */
  color?: ButtonColor | ((item: T) => ButtonColor);
  render?: undefined;
  component?: undefined;
}

export interface CustomItemAction<T> {
  /**
   * Renders a custom action: a component receiving `@item` and
   * `@enabled` (upstream `render(item, enabled)`).
   */
  component: ComponentLike<{ Args: { item: T; enabled: boolean } }>;
  available?: (item: T) => boolean;
  enabled?: (item: T) => boolean;
  isPrimary?: boolean;
  showOnHover?: boolean;
}

export type Action<T extends object> = DefaultItemAction<T> | CustomItemAction<T>;

export const isCustomItemAction = <T extends object>(
  action: Action<T>
): action is CustomItemAction<T> => {
  return Object.prototype.hasOwnProperty.call(action, 'component');
};

export const callWithItemIfFunction =
  <T>(item: T) =>
  <U>(prop: U | ((item: T) => U)): U =>
    typeof prop === 'function' ? (prop as (item: T) => U)(item) : prop;

export interface EuiTableSortingType<T> {
  /** The field (or column name) sorted on. */
  sort?: {
    field: keyof T;
    direction: 'asc' | 'desc';
  };
  /** Clicking a descending column unsorts it (EuiInMemoryTable). */
  allowNeutralSort?: boolean;
  /** Sorting on every field column. */
  enableAllColumns?: boolean;
  /** Shows the sort without letting the user change it. */
  readOnly?: boolean;
}

export interface EuiTableSelectionType<T> {
  /** Called whenever the selection changes. Required with `selected`. */
  onSelectionChange?: (selection: T[]) => void;
  /** Whether an item is selectable. */
  selectable?: (item: T) => boolean;
  /** Tooltip of an item's checkbox (e.g. why it is not selectable). */
  selectableMessage?: (selectable: boolean, item: T) => string;
  /** Initially selected items (uncontrolled). Ignored with `selected`. */
  initialSelected?: T[];
  /** The selected items (controlled). */
  selected?: T[];
}

export interface Criteria<T> {
  /** The shown page, when the items are a page of a bigger set. */
  page?: {
    index: number;
    size: number;
  };
  /** The sort criteria. */
  sort?: {
    field: keyof T;
    direction: 'asc' | 'desc';
  };
}

export interface CriteriaWithPagination<T> extends Criteria<T> {
  page: {
    index: number;
    size: number;
  };
}

/** Attributes for a row or cell; `onClick` makes a row clickable. */
export type EuiTableElementProps = Record<string, unknown>;

export type RowPropsCallback<T> = (item: T) => EuiTableElementProps;
export type CellPropsCallback<T extends object> = (
  item: T,
  column: EuiBasicTableColumn<T>
) => EuiTableElementProps;

const dataTypesProfiles: Record<
  EuiTableDataType,
  { align: 'left' | 'right'; render: (value: any) => string }
> = {
  auto: {
    align: 'left',
    render: (value: any) => formatAuto(value)
  },
  string: {
    align: 'left',
    render: (value: any) => formatText(value) as string
  },
  number: {
    align: 'right',
    render: (value: number | null) => formatNumber(value)
  },
  boolean: {
    align: 'left',
    render: (value: boolean) => formatBoolean(value)
  },
  date: {
    align: 'left',
    render: (value: any) => formatDate(value)
  }
};

const DATA_TYPES = Object.keys(dataTypesProfiles);

function profile(dataType: EuiTableDataType = 'auto') {
  const found = dataTypesProfiles[dataType];
  if (!found) {
    throw new Error(
      `Unknown dataType [${dataType}]. The supported data types are [${DATA_TYPES.join(
        ', '
      )}]`
    );
  }
  return found;
}

export function getRendererForDataType(dataType?: EuiTableDataType) {
  return profile(dataType).render;
}

export function getAlignForDataType(dataType?: EuiTableDataType) {
  return profile(dataType).align;
}

export function getItemId<T>(item: T, itemId?: ItemId<T>): any {
  if (itemId) {
    if (typeof itemId === 'function') {
      return itemId(item);
    }
    return (item as Record<string | number, unknown>)[itemId];
  }
  return undefined;
}

export function getRowProps<T>(
  item: T,
  rowProps?: EuiTableElementProps | RowPropsCallback<T>
): EuiTableElementProps {
  if (rowProps) {
    if (typeof rowProps === 'function') {
      return rowProps(item);
    }
    return rowProps;
  }
  return {};
}

export function getCellProps<T extends object>(
  item: T,
  column: EuiBasicTableColumn<T>,
  cellProps?: EuiTableElementProps | CellPropsCallback<T>
): EuiTableElementProps {
  if (cellProps) {
    if (typeof cellProps === 'function') {
      return cellProps(item, column);
    }
    return cellProps;
  }
  return {};
}

/**
 * Applies upstream's spread props to an element: `on<Event>` functions
 * become listeners, `className`/`class` add classes and the other
 * strings/numbers/booleans become attributes (`style` too). Removed when
 * the props change.
 */
export const elementProps = modifier(
  (element: HTMLElement, [props]: [EuiTableElementProps | undefined]) => {
    if (!props) return;
    const cleanups: Array<() => void> = [];
    for (const [key, value] of Object.entries(props)) {
      if (value == null || value === false) continue;
      if (/^on[A-Z]/.test(key) && typeof value === 'function') {
        const type = key.slice(2).toLowerCase();
        const listener = value as EventListener;
        element.addEventListener(type, listener);
        cleanups.push(() => element.removeEventListener(type, listener));
      } else if (key === 'className' || key === 'class') {
        const classes = String(value as string).split(/\s+/).filter(Boolean);
        element.classList.add(...classes);
        cleanups.push(() => element.classList.remove(...classes));
      } else if (
        typeof value === 'string' ||
        typeof value === 'number' ||
        value === true
      ) {
        const previous = element.getAttribute(key);
        element.setAttribute(key, value === true ? '' : String(value));
        cleanups.push(() =>
          previous == null
            ? element.removeAttribute(key)
            : element.setAttribute(key, previous)
        );
      }
    }
    return () => cleanups.forEach((cleanup) => cleanup());
  }
);
