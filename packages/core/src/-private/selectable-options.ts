import type { EuiTextTruncateSignature } from '../components/eui-text-truncate';
import type { EuiTooltipArgs } from '../components/eui-tool-tip';

/** EuiTextTruncate arguments for options (upstream `truncationProps`). */
export type EuiSelectableTruncationProps = Partial<
  Omit<EuiTextTruncateSignature['Args'], 'text'>
>;

/** EuiToolTip arguments for an option's tooltip (upstream `toolTipProps`). */
export type EuiSelectableToolTipProps = Partial<
  Pick<
    EuiTooltipArgs,
    | 'position'
    | 'delay'
    | 'title'
    | 'offset'
    | 'className'
    | 'css'
    | 'anchorClassName'
  >
>;

export interface EuiSelectableOption {
  /** The option's text; also what the search matches. */
  label: string;
  /**
   * `'on'` (selected / included), `'off'` (excluded), `'mixed'` (included
   * for some; pressing it checks it) or nothing.
   */
  checked?: 'on' | 'off' | 'mixed';
  /** Disables the option. */
  disabled?: boolean;
  /**
   * With `disabled`: the option stays reachable with the keyboard (and
   * shows its tooltip) but cannot be selected; it gets `aria-disabled`.
   */
  hasAriaDisabled?: boolean;
  /** A heading between groups of options, not selectable. */
  isGroupLabel?: boolean;
  /** Text before the label. */
  prepend?: string;
  /** Text after the label (e.g. a count). */
  append?: string;
  /** Text the search matches instead of the label (also the label's `title`). */
  searchableLabel?: string;
  /** Unique key, when labels repeat. */
  key?: string;
  /** Extra classes for the option's `<li>`. */
  className?: string;
  /** `data-test-subj` of the option's `<li>`. */
  'data-test-subj'?: string;
  /**
   * `'truncate'` (default) or `'wrap'`; overrides `listProps.textWrap`.
   * Wrapping needs `listProps.isVirtualized: false`.
   */
  textWrap?: 'truncate' | 'wrap';
  /** EuiTextTruncate arguments, merged over `listProps.truncationProps`. */
  truncationProps?: EuiSelectableTruncationProps;
  /** Tooltip text shown on hover and while the option is current. */
  toolTipContent?: string;
  /** EuiToolTip arguments of that tooltip (`position` defaults to `'left'`). */
  toolTipProps?: EuiSelectableToolTipProps;
  /** Extra data for a custom `<:option>` block. */
  data?: Record<string, unknown>;
  [key: string]: unknown;
}

export interface EuiSelectableOptionMatcherArgs {
  option: EuiSelectableOption;
  /** The search as typed. */
  searchValue: string;
  /** The search lower-cased. */
  normalizedSearchValue: string;
}

/** Decides whether an option matches the search (upstream `optionMatcher`). */
export type EuiSelectableOptionMatcher = (
  args: EuiSelectableOptionMatcherArgs
) => boolean;

function searchableLabel(option: EuiSelectableOption): string {
  return (option.searchableLabel || option.label).trim().toLowerCase();
}

/**
 * Upstream default matcher: the option's `searchableLabel` (or `label`)
 * contains the search, ignoring case.
 */
export function createPartialStringEqualityOptionMatcher(): EuiSelectableOptionMatcher {
  return ({ option, normalizedSearchValue }) =>
    searchableLabel(option).includes(normalizedSearchValue);
}

const defaultMatcher = createPartialStringEqualityOptionMatcher();

/**
 * The options matching the search (by default: whose label or
 * `searchableLabel` contains it, ignoring case). With `isPreFiltered` every
 * option matches (the options were already filtered, e.g. by a server).
 * Always a new array; the options themselves are not copied.
 */
export function getMatchingOptions<T extends EuiSelectableOption>(
  options: readonly T[],
  searchValue = '',
  isPreFiltered: unknown = false,
  optionMatcher: EuiSelectableOptionMatcher = defaultMatcher
): T[] {
  const normalizedSearchValue = searchValue.toLowerCase();

  if (isPreFiltered || !normalizedSearchValue) return [...options];

  return options.filter((option) =>
    optionMatcher({ option, searchValue, normalizedSearchValue })
  );
}

/** Whether the keyboard can make the option current (upstream). */
export function isNavigable(option: EuiSelectableOption | undefined): boolean {
  return Boolean(
    option && !option.isGroupLabel && (!option.disabled || option.hasAriaDisabled)
  );
}

/**
 * All options with `option` pressed, plus the changed option: unchecked
 * options get checked (with `singleSelection`, the others are unchecked),
 * checked ones get excluded (`allowExclusions`) or unchecked (unless
 * `singleSelection` is `'always'`), excluded ones get unchecked. Disabled
 * options do nothing. The given options are never mutated.
 */
export function toggleOptionWithChange<T extends EuiSelectableOption>(
  options: readonly T[],
  option: T,
  {
    allowExclusions,
    singleSelection
  }: { allowExclusions?: boolean; singleSelection?: boolean | 'always' } = {}
): { options: T[]; changedOption: T } | undefined {
  if (option.disabled) return undefined;

  const unchecked = (item: T): T => {
    const { checked: _checked, ...rest } = item;

    return rest as T;
  };
  let changedOption: T = { ...option };
  const changed = (item: T): T => (changedOption = item);

  let next: T[];

  if (option.checked === 'on' && allowExclusions) {
    next = options.map((item) =>
      item === option ? changed({ ...item, checked: 'off' }) : { ...item }
    );
  } else if (option.checked === 'on' || option.checked === 'off') {
    next = options.map((item) =>
      item === option && singleSelection !== 'always'
        ? changed(unchecked(item))
        : { ...item }
    );
  } else {
    next = options.map((item) => {
      if (item === option) return changed({ ...item, checked: 'on' });

      return singleSelection ? unchecked(item) : { ...item };
    });
  }

  return { options: next, changedOption };
}

/** {@link toggleOptionWithChange} without the changed option. */
export function toggleOption<T extends EuiSelectableOption>(
  options: readonly T[],
  option: T,
  settings: { allowExclusions?: boolean; singleSelection?: boolean | 'always' } = {}
): T[] | undefined {
  return toggleOptionWithChange(options, option, settings)?.options;
}
