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

const isGroupOption = (option: unknown): option is { options: unknown[] } =>
  Boolean(
    option &&
      typeof option === 'object' &&
      Array.isArray((option as { options?: unknown }).options)
  );

/** Upstream `flattenOptionGroups`: the options of groups, in one list. */
export function flattenOptionGroups(options: readonly unknown[]): unknown[] {
  return options.reduce<unknown[]>((all, option) => {
    if (isGroupOption(option)) return all.concat(option.options);
    all.push(option);

    return all;
  }, []);
}

/**
 * Upstream `createPartialStringEqualityOptionMatcher` (case-sensitive
 * variant), as an ember-power-select `@matcher`: `-1` for no match. The
 * search text is trimmed like upstream's `normalizedSearchValue`.
 */
export function partialStringMatcher(
  searchField: string | undefined,
  isCaseSensitive: boolean
): (option: unknown, searchText: string) => number {
  return (option, searchText) => {
    const search = transformForCaseSensitivity(
      searchText.trim(),
      isCaseSensitive
    );

    if (!search) return 0;

    const label = transformForCaseSensitivity(
      comboBoxOptionLabel(option, searchField).trim(),
      isCaseSensitive
    );

    return label.includes(search) ? 0 : -1;
  };
}

/**
 * Upstream `sortMatchesBy="startsWith"`: options whose label starts with
 * the search text first, the others after them, both in their original
 * order. Upstream sorts its flat list; here groups keep their options and
 * each group is sorted the same way.
 */
export function sortMatchesByStartsWith<T>(
  options: readonly T[],
  searchText: string,
  searchField: string | undefined,
  isCaseSensitive: boolean
): T[] {
  const search = transformForCaseSensitivity(
    searchText.trim(),
    isCaseSensitive
  );
  const startWith: T[] = [];
  const others: T[] = [];

  options.forEach((option) => {
    if (isGroupOption(option)) {
      startWith.push({
        ...option,
        options: sortMatchesByStartsWith(
          option.options,
          searchText,
          searchField,
          isCaseSensitive
        )
      } as T);

      return;
    }

    const label = transformForCaseSensitivity(
      comboBoxOptionLabel(option, searchField),
      isCaseSensitive
    );

    (label.startsWith(search) ? startWith : others).push(option);
  });

  return [...startWith, ...others];
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
