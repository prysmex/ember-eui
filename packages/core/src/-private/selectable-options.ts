export interface EuiSelectableOption {
  /** The option's text; also what the search matches. */
  label: string;
  /** `'on'` (selected / included), `'off'` (excluded) or nothing. */
  checked?: 'on' | 'off';
  /** Disables the option. */
  disabled?: boolean;
  /** A heading between groups of options, not selectable. */
  isGroupLabel?: boolean;
  /** Text before the label. */
  prepend?: string;
  /** Text after the label (e.g. a count). */
  append?: string;
  /** Text the search matches instead of the label. */
  searchableLabel?: string;
  /** Unique key, when labels repeat. */
  key?: string;
  /** Extra classes for the option's `<li>`. */
  className?: string;
  [key: string]: unknown;
}

function searchableLabel(option: EuiSelectableOption): string {
  return (option.searchableLabel ?? option.label).trim().toLowerCase();
}

/**
 * The options whose label (or `searchableLabel`) contains the search,
 * ignoring case. With `isPreFiltered` every option matches (the options
 * were already filtered, e.g. by a server).
 */
export function getMatchingOptions<T extends EuiSelectableOption>(
  options: T[],
  searchValue = '',
  isPreFiltered = false
): T[] {
  const search = searchValue.toLowerCase();

  if (isPreFiltered || !search) return [...options];

  return options.filter((option) => searchableLabel(option).includes(search));
}

/**
 * All options with `option` pressed: unchecked options get checked (with
 * `singleSelection`, the others are unchecked), checked ones get excluded
 * (`allowExclusions`) or unchecked (unless `singleSelection` is
 * `'always'`), excluded ones get unchecked. Disabled options do nothing.
 */
export function toggleOption<T extends EuiSelectableOption>(
  options: T[],
  option: T,
  {
    allowExclusions,
    singleSelection
  }: { allowExclusions?: boolean; singleSelection?: boolean | 'always' } = {}
): T[] | undefined {
  if (option.disabled) return undefined;

  const unchecked = (item: T): T => {
    const { checked: _checked, ...rest } = item;

    return rest as T;
  };

  if (option.checked === 'on' && allowExclusions) {
    return options.map((item) => (item === option ? { ...item, checked: 'off' } : { ...item }));
  }

  if (option.checked === 'on' || option.checked === 'off') {
    return options.map((item) =>
      item === option && singleSelection !== 'always' ? unchecked(item) : { ...item }
    );
  }

  return options.map((item) => {
    if (item === option) return { ...item, checked: 'on' };

    return singleSelection ? unchecked(item) : { ...item };
  });
}
