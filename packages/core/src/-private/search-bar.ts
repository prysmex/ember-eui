/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

// Filter configuration types of EuiSearchBar (upstream EUI 123.1.0
// `components/search_bar/filters/*`).

import type { Query } from '../utils/eui/search-bar/query.ts';
import type {
  Clause,
  OperatorType,
  Value
} from '../utils/eui/search-bar/ast.ts';
import type { ComponentLike } from '@glint/template';

export interface IsFilterConfigType {
  type: 'is';
  field: string;
  name: string;
  negatedName?: string;
  available?: () => boolean;
}

export interface FieldValueToggleFilterConfigType {
  type: 'field_value_toggle';
  field: string;
  value: Value;
  name: string;
  negatedName?: string;
  available?: () => boolean;
  operator?: OperatorType;
}

export interface FieldValueToggleGroupFilterItemType {
  value: string | number | boolean;
  name: string;
  negatedName?: string;
  operator?: OperatorType;
}

export interface FieldValueToggleGroupFilterConfigType {
  type: 'field_value_toggle_group';
  field: string;
  /** See {@link FieldValueToggleGroupFilterItemType} */
  items: FieldValueToggleGroupFilterItemType[];
  available?: () => boolean;
}

export interface FieldValueOptionType {
  field?: string;
  value: Value;
  name?: string;
  /**
   * Ember: replaces upstream's `view` (a React node) with plain text shown
   * instead of the name; use the filter's `<:option>` block for markup.
   */
  view?: string;
}

type OptionsLoader = () => Promise<FieldValueOptionType[]>;

type OptionsFilter = (
  name: string,
  query: string,
  options?: FieldValueOptionType[]
) => boolean;

export type MultiSelect = boolean | 'and' | 'or';

export interface FieldValueSelectionFilterConfigType {
  type: 'field_value_selection';
  field?: string;
  name: string;
  /** See {@link FieldValueOptionType} */
  options: FieldValueOptionType[] | OptionsLoader;
  filterWith?: 'prefix' | 'includes' | OptionsFilter;
  cache?: number;
  multiSelect?: MultiSelect;
  loadingMessage?: string;
  noOptionsMessage?: string;
  searchThreshold?: number;
  available?: () => boolean;
  autoClose?: boolean;
  operator?: OperatorType;
  autoSortOptions?: boolean;
}

/** The args a `custom_component` filter receives. */
export interface CustomComponentProps {
  query: Query;
  onChange?: (query: Query) => void;
}

export interface CustomComponentFilterConfigType {
  type: 'custom_component';
  /** An Ember component receiving `@query` and `@onChange`. */
  component: ComponentLike<{ Args: CustomComponentProps }>;
  available?: () => boolean;
}

export type SearchFilterConfig =
  | IsFilterConfigType
  | FieldValueSelectionFilterConfigType
  | FieldValueToggleFilterConfigType
  | FieldValueToggleGroupFilterConfigType
  | CustomComponentFilterConfigType;

/** Upstream `resolveDisplay` of the is/toggle filters. */
export function resolveToggleDisplay(
  clause: Clause | undefined,
  name: string,
  negatedName: string | undefined,
  isMust: (clause: Clause) => boolean
): { hasActiveFilters: boolean; name: string } {
  if (clause == null) {
    return { hasActiveFilters: false, name };
  }
  return isMust(clause)
    ? { hasActiveFilters: true, name }
    : {
        hasActiveFilters: true,
        name: negatedName ? negatedName : `Not ${name}`
      };
}
