/**
 * Combo box helpers. The group label style port it needs is shared with
 * EuiSelectableList (`utils/eui/selectable.ts`).
 */
import type { CSSObject } from '@emotion/css/create-instance';

/**
 * Ember has no React global reset: box sizing for the combo box's own
 * elements (upstream `*` reset) and the list's `button`-free rows.
 */
export const comboBoxBoxReset: CSSObject = {
  boxSizing: 'border-box',
  '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
};

/** The text of an option: strings as they are, else `label` (or `@searchField`). */
export function comboBoxOptionLabel(option: unknown, searchField?: string): string {
  if (typeof option === 'string') return option;
  if (typeof option === 'number') return String(option);
  if (option && typeof option === 'object') {
    const record = option as Record<string, unknown>;
    const value = record[searchField ?? 'label'] ?? record['label'];

    if (typeof value === 'string' || typeof value === 'number') {
      return String(value);
    }
  }

  return '';
}

/*
 * Matching helpers below are ported from @elastic/eui 123.1.0
 * `components/combo_box/matching_options.ts` and `combo_box/utils.tsx`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */

/** Upstream `SortMatchesBy`. */
export type EuiComboBoxSortMatchesBy = 'none' | 'startsWith';

/** Upstream `transformForCaseSensitivity`. */
export const transformForCaseSensitivity = (
  text: string,
  isCaseSensitive?: boolean
): string => (isCaseSensitive ? text : text.toLowerCase());

/**
 * A group: upstream's `{ label, options }` or ember-power-select's
 * `{ groupName, options }`.
 */
export const isComboBoxGroup = (
  option: unknown
): option is { options: unknown[]; groupName?: string; label?: string } =>
  Boolean(
    option &&
      typeof option === 'object' &&
      Array.isArray((option as { options?: unknown }).options)
  );

/** The title of a group (`groupName`, else upstream's `label`). */
export const comboBoxGroupLabel = (group: {
  groupName?: string;
  label?: string;
}): string => String(group.groupName ?? group.label ?? '');

/** Upstream `flattenOptionGroups`: the options of groups, in one list. */
export function flattenOptionGroups(options: readonly unknown[]): unknown[] {
  return options.reduce<unknown[]>((all, option) => {
    if (isComboBoxGroup(option)) return all.concat(option.options);
    all.push(option);

    return all;
  }, []);
}

/** Upstream `EuiComboBoxOptionMatcherArgs`. */
export interface EuiComboBoxOptionMatcherArgs {
  /** The option being matched. */
  option: any;
  /** The search text, as typed. */
  searchValue: string;
  /** The search text trimmed, and lower case unless case-sensitive. */
  normalizedSearchValue: string;
  /** Whether matching is case-sensitive. */
  isCaseSensitive: boolean;
}

/** Upstream `EuiComboBoxOptionMatcher`: `true` when the option matches. */
export type EuiComboBoxOptionMatcher = (
  args: EuiComboBoxOptionMatcherArgs
) => boolean;

/**
 * Upstream `createPartialStringEqualityOptionMatcher`: options whose label
 * (trimmed) includes the normalized search text.
 */
export function createPartialStringEqualityOptionMatcher(
  searchField?: string
): EuiComboBoxOptionMatcher {
  return ({ option, isCaseSensitive, normalizedSearchValue }) => {
    if (!normalizedSearchValue) return true;

    return transformForCaseSensitivity(
      comboBoxOptionLabel(option, searchField).trim(),
      isCaseSensitive
    ).includes(normalizedSearchValue);
  };
}

const keyOf = (option: unknown): unknown =>
  option && typeof option === 'object'
    ? (option as { key?: unknown }).key
    : undefined;

/**
 * Upstream's "already selected" test of `getMatchingOptions`: a selected
 * option has the same label (case per `isCaseSensitive`) and, when the
 * option has a `key`, the same key. The same object always is.
 */
export function isComboBoxOptionSelected(
  option: unknown,
  selectedOptions: readonly unknown[],
  searchField?: string,
  isCaseSensitive?: boolean
): boolean {
  if (!selectedOptions.length) return false;
  if (selectedOptions.includes(option)) return true;

  const label = comboBoxOptionLabel(option, searchField);

  if (!label) return false;

  const normalized = transformForCaseSensitivity(label, isCaseSensitive);
  const key = keyOf(option);

  return selectedOptions.some(
    (selected) =>
      transformForCaseSensitivity(
        comboBoxOptionLabel(selected, searchField),
        isCaseSensitive
      ) === normalized &&
      (key === undefined || keyOf(selected) === key)
  );
}

/**
 * Upstream single selection check mark: the selected option has the same
 * label and key (or is the same object).
 */
export function isComboBoxOptionChecked(
  option: unknown,
  selectedOptions: readonly unknown[] | undefined,
  searchField?: string
): boolean {
  const selected = selectedOptions?.[0];

  if (selected === undefined) return false;
  if (selected === option) return true;

  const label = comboBoxOptionLabel(option, searchField);

  return (
    Boolean(label) &&
    comboBoxOptionLabel(selected, searchField) === label &&
    keyOf(selected) === keyOf(option)
  );
}

interface GetMatchingOptions {
  options: readonly unknown[];
  selectedOptions: readonly unknown[];
  searchValue: string;
  optionMatcher: EuiComboBoxOptionMatcher;
  searchField?: string;
  isCaseSensitive?: boolean;
  isPreFiltered?: boolean;
  showPrevSelected?: boolean;
  sortMatchesBy?: EuiComboBoxSortMatchesBy;
}

/** A group title in the flat list of matches (upstream `isGroupLabelOption`). */
export interface ComboBoxGroupLabel {
  isGroupLabelOption: true;
  group: { options: unknown[]; groupName?: string; label?: string };
}

export const isComboBoxGroupLabel = (
  entry: unknown
): entry is ComboBoxGroupLabel =>
  Boolean(
    entry &&
      typeof entry === 'object' &&
      (entry as ComboBoxGroupLabel).isGroupLabelOption === true &&
      'group' in entry
  );

/**
 * Upstream `getMatchingOptions`, as a flat list with group titles: the
 * options (not yet selected, unless `showPrevSelected`) matching the search
 * text, groups with matches preceded by their title, and with
 * `sortMatchesBy: 'startsWith'` the entries (titles included) whose label
 * starts with the search text first.
 */
export function getMatchingEntries({
  options,
  selectedOptions,
  searchValue,
  optionMatcher,
  searchField,
  isCaseSensitive = false,
  isPreFiltered = false,
  showPrevSelected = false,
  sortMatchesBy = 'none'
}: GetMatchingOptions): unknown[] {
  const normalizedSearchValue = transformForCaseSensitivity(
    searchValue.trim(),
    isCaseSensitive
  );
  let entries: unknown[] = [];

  const collect = (accumulator: unknown[], option: unknown) => {
    // only options not selected yet, unless requested
    if (
      !showPrevSelected &&
      isComboBoxOptionSelected(
        option,
        selectedOptions,
        searchField,
        isCaseSensitive
      )
    ) {
      return;
    }

    if (
      isPreFiltered ||
      !normalizedSearchValue ||
      optionMatcher({
        option,
        searchValue,
        normalizedSearchValue,
        isCaseSensitive
      })
    ) {
      accumulator.push(option);
    }
  };

  options.forEach((option) => {
    if (isComboBoxGroup(option)) {
      const matches: unknown[] = [];

      option.options.forEach((child) => collect(matches, child));

      if (matches.length > 0) {
        entries.push({ isGroupLabelOption: true, group: option });
        // concat over spreading, for large groups (upstream)
        entries = entries.concat(matches);
      }
    } else {
      collect(entries, option);
    }
  });

  if (sortMatchesBy === 'startsWith') {
    const startWith: unknown[] = [];
    const others: unknown[] = [];

    entries.forEach((entry) => {
      const label = isComboBoxGroupLabel(entry)
        ? comboBoxGroupLabel(entry.group)
        : comboBoxOptionLabel(entry, searchField);

      (transformForCaseSensitivity(label, isCaseSensitive).startsWith(
        normalizedSearchValue
      )
        ? startWith
        : others
      ).push(entry);
    });

    return [...startWith, ...others];
  }

  return entries;
}

/**
 * The flat list of matches as ember-power-select options: every option
 * after a group title belongs to that group (as rendered upstream), the
 * others are top level. Groups are copies with the matching options (and a
 * `groupName`), the options themselves are never copied.
 */
export function entriesToPowerSelectOptions(entries: readonly unknown[]) {
  const result: unknown[] = [];
  let current: { options: unknown[]; groupName?: string } | undefined;

  entries.forEach((entry) => {
    if (isComboBoxGroupLabel(entry)) {
      current = {
        ...entry.group,
        groupName: comboBoxGroupLabel(entry.group),
        options: []
      };
      result.push(current);
    } else if (current) {
      current.options.push(entry);
    } else {
      result.push(entry);
    }
  });

  return result;
}

/**
 * Groups and their options in one list (group objects included), the rows
 * of EuiComboBox's list and upstream's `matchingOptions` order.
 */
export function flattenComboBoxRows(options: readonly unknown[]): unknown[] {
  const rows: unknown[] = [];

  options.forEach((option) => {
    if (isComboBoxGroup(option) && 'groupName' in option) {
      rows.push(option);
      option.options.forEach((child) => rows.push(child));
    } else {
      rows.push(option);
    }
  });

  return rows;
}

/** An option that can be highlighted or chosen (not a group, not disabled). */
export const isSelectableRow = (row: unknown, group?: unknown): boolean =>
  !(isComboBoxGroup(row) && 'groupName' in (row as object)) &&
  !(
    row &&
    typeof row === 'object' &&
    (row as { disabled?: boolean }).disabled === true
  ) &&
  !(
    group &&
    typeof group === 'object' &&
    (group as { disabled?: boolean }).disabled === true
  );

/**
 * Upstream `findNextSelectableOptionIndex`: from `startIndex`, the first
 * selectable row in `direction`, wrapping around; `-1` when none.
 */
export function findNextSelectableIndex(
  rows: readonly unknown[],
  selectable: (index: number) => boolean,
  startIndex: number,
  direction: 1 | -1 = 1
): number {
  if (!rows.length) return -1;

  let index = startIndex;

  for (let count = 0; count < rows.length; count++) {
    if (selectable(index)) return index;

    index = (index + direction + rows.length) % rows.length;
  }

  return -1;
}

/**
 * Upstream `getSelectedOptionForSearchValue`: the selected option whose
 * label equals the text.
 */
export function selectedOptionForSearchValue(
  selectedOptions: readonly unknown[],
  searchValue: string,
  searchField: string | undefined,
  isCaseSensitive?: boolean
): unknown {
  const search = transformForCaseSensitivity(searchValue, isCaseSensitive);

  return selectedOptions.find(
    (option) =>
      transformForCaseSensitivity(
        comboBoxOptionLabel(option, searchField),
        isCaseSensitive
      ) === search
  );
}

/**
 * Upstream `EuiComboBoxOptionAppendPrepend` spacing: margin between an
 * option's `prepend` / `append` and its text, with block icons so they
 * align with the text.
 */
export function comboBoxAppendPrependStyles(
  margin: string
): { prepend: CSSObject; append: CSSObject } {
  const centerIcons = { '.euiIcon': { display: 'block' } };

  return {
    prepend: { marginInlineEnd: margin, ...centerIcons },
    append: { marginInlineStart: margin, ...centerIcons }
  };
}

/**
 * Option `prepend` / `append` and EuiComboBox's `@prepend` / `@append`:
 * text, or a component (rendered with the option as `@option`).
 */
export const isTextNode = (value: unknown): boolean =>
  typeof value === 'string' ||
  typeof value === 'number' ||
  // htmlSafe strings render as HTML, like text
  (Boolean(value) &&
    typeof value === 'object' &&
    typeof (value as { toHTML?: unknown }).toHTML === 'function');
