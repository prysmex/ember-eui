import 'ember-basic-dropdown/styles';

import Component from '@glimmer/component';
import { getElementZIndex } from '../utils/popover/index.ts';
import { cached, tracked } from '@glimmer/tracking';
import { isArray } from '@ember/array';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { htmlSafe, isHTMLSafe } from '@ember/template';
import { isEqual } from '@ember/utils';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import queue from '@nullvoxpopuli/ember-composable-helpers/helpers/queue';
import PowerSelect from 'ember-power-select/components/power-select';
import emberPowerSelectIsGroup from 'ember-power-select/helpers/ember-power-select-is-group';
import { and, not } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  comboBoxBoxReset,
  comboBoxOptionLabel,
  createPartialStringEqualityOptionMatcher,
  entriesToPowerSelectOptions,
  findNextSelectableIndex,
  flattenComboBoxRows,
  flattenOptionGroups,
  getMatchingEntries,
  isComboBoxGroupLabel,
  isComboBoxOptionChecked,
  isComboBoxOptionSelected,
  selectedOptionForSearchValue,
  transformForCaseSensitivity
} from '../utils/eui/combo-box.ts';
import {
  euiBackgroundColor,
  euiBorderColor,
  euiComboBoxStyles,
  euiFormVariables,
  euiPaddingSize,
  euiPanelStyles,
  euiPopoverPanelStyles,
  euiScreenReaderOnly
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiComboBoxOptionText from './eui-combo-box/option-text.gts';
import EuiComboBoxCreateOption from './eui-combo-box/create-option.gts';
import EuiComboBoxGroup from './eui-combo-box/group.gts';
import EuiComboBoxNoMatchesMessage from './eui-combo-box/no-matches-message.gts';
import EuiComboBoxOptions from './eui-combo-box/options.gts';
import EuiComboBoxSearchMessage from './eui-combo-box/search-message.gts';
import EuiComboBoxTrigger from './eui-combo-box/trigger.gts';

import type EuiI18n from '../services/eui-i18n';
import type {
  EuiComboBoxOptionMatcher,
  EuiComboBoxSortMatchesBy
} from '../utils/eui/combo-box.ts';
import type { EuiComboBoxNode } from './eui-combo-box/node.gts';
import type { EuiComboBoxTruncationProps } from './eui-combo-box/option-text.gts';
import type { EuiTooltipArgs } from './eui-tool-tip';

export type {
  EuiComboBoxNode,
  EuiComboBoxOptionMatcher,
  EuiComboBoxTruncationProps
};

/** `@onCreateOption`: the value, and all options with groups flattened. */
export type EuiComboBoxOnCreateOption = (
  search: string,
  flattenedOptions: any[]
) => boolean | undefined | void;

/**
 * An option object (options can also be plain strings). Every key is
 * optional; `label` is the text by default (see `@searchField`).
 */
export interface EuiComboBoxOptionOption {
  label?: string;
  /** Disables the option. */
  disabled?: boolean;
  /** Pill color, see `EuiBadge`. */
  color?: string;
  /** Text or a component before the label, in the list and the pill. */
  prepend?: EuiComboBoxNode;
  /** Text or a component after the label, in the list and the pill. */
  append?: EuiComboBoxNode;
  /** Tooltip of the option in the list (not on disabled options). */
  toolTipContent?: string;
  /** More `EuiToolTip` arguments for `toolTipContent`. */
  toolTipProps?: Partial<
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
  /** Truncation of this option, merged over `@truncationProps`. */
  truncationProps?: EuiComboBoxTruncationProps;
  /** Title of the option text (defaults to the label while truncated by CSS). */
  title?: string;
  /** A group: its options. Groups use `groupName` for their title. */
  options?: unknown[];
  [key: string]: unknown;
}

interface PromiseProxy<T> extends Promise<T> {
  content: any;
}

interface Select {
  selected: any;
  actions: {
    search: (str: string) => void;
  };
}

export interface EuiComboBoxSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Allows only one selected option (still passed to `@onChange` as a
     * one-item array). `{ asPlainText: true }` shows the selection as the
     * input's text instead of a pill. Defaults to multiple selection.
     */
    singleSelection?:
      | boolean
      | {
          asPlainText?: boolean;
        };
    /**
     * Lets the user add the typed text as a new option: shows an "add"
     * option when nothing matches (or always, with
     * `@alwaysShowCreateOption`), and Enter or leaving the combo box adds
     * the text (upstream). Called with the search text and all options
     * (groups flattened); return `false` to reject it. Add the result to
     * `@options` / `@selectedOptions` yourself. Text equal to a selected
     * option is not added again, and text equal to the only matching
     * option selects that option.
     */
    onCreateOption?: EuiComboBoxOnCreateOption;
    /** Shows the "add" option even when some options match. */
    alwaysShowCreateOption?: boolean;
    /**
     * The options: strings, or objects with a `label` (or `@searchField`).
     * Groups are `{ groupName: 'Fruits', options: [...] }` (or upstream's
     * `{ label: 'Fruits', options: [...] }`). In multiple selection the
     * selected options are not listed (upstream). A promise is supported
     * (shows `@loadingMessage` while pending). Never changed by the combo
     * box; pass a new array to change the options.
     */
    options: any[];
    /**
     * Custom search, e.g. to query a server: `(term, select) => results`
     * (or a promise). Without it the options are filtered locally, by
     * `@searchField` for objects. Selected options are left out of the
     * results in multiple selection.
     */
    search?: (term: string, select: Select) => any[] | PromiseProxy<any[]>;
    /** Key of object options to match the search text against, e.g. `'label'`. */
    searchField?: string;
    /** Shows the invalid state. */
    isInvalid?: boolean;
    /** Stretches the combo box to its container's width. */
    fullWidth?: boolean;
    /** Message shown before typing when `@search` is set. Defaults to "Type to search". */
    searchMessage?: string;
    /** Allows typing to filter options. Defaults to `true`. */
    searchEnabled?: boolean;
    /** Shows a button clearing the selection. Defaults to `true`. */
    isClearable?: boolean;
    /** Shows a spinner in the input and the list, e.g. while options load. */
    isLoading?: boolean;
    /** Disables the combo box. */
    isDisabled?: boolean;
    /** @deprecated Has no effect; use `@isDisabled`. */
    readOnly?: boolean;
    /** Component rendered instead of `@searchMessage`. */
    searchMessageComponent?: any;
    /** Smaller combo box, for dense forms. */
    compressed?: boolean;
    /** Called when the input gets focus (which opens the list, upstream). */
    onFocus?: (e: FocusEvent) => void;
    /** Called when the input loses focus. */
    onBlur?: (e: FocusEvent) => void;
    /** Called when the options list closes; return `false` to keep it open. */
    onClose?: (e: Event) => void;
    /** Called when the options list opens; return `false` to keep it closed. */
    onOpen?: (e: Event) => void;
    /**
     * Renders the options list next to the input instead of in a portal
     * at the end of the page (e.g. inside modals with their own scrolling).
     */
    renderInPlace?: boolean;
    /**
     * Text (HTML) of the "add" option; `{searchText}` is replaced by the
     * typed text. Defaults to "Add **{searchText}** as custom option".
     */
    customOptionText?: string;
    /** Message while `@options` or `@search` load. Defaults to "Loading options...". */
    loadingMessage?: any;
    /** Component rendering each selected option (pill). */
    selectedItemComponent?: any;
    /** Component rendered above the options. */
    beforeOptionsComponent?: any;
    /** Component rendered instead of `@placeholder`. */
    placeholderComponent?: any;
    /** Component rendered below the options. */
    afterOptionsComponent?: any;
    /** Placeholder of the search input. */
    searchPlaceholder?: any;
    /** Extra class for the options list. */
    dropdownClass?: string;
    /** The selected options (items of `@options`). */
    selectedOptions?: any[];
    /**
     * Called with the new selection (an array, also with
     * `@singleSelection`). Update `@selectedOptions` here.
     */
    onChange: (selected: any[]) => void;
    /** Text shown when nothing is selected. */
    placeholder?: string;
    /** Anything, passed to custom components as `@extra`. */
    extra?: any;
    /**
     * Closes the options list after selecting one. Defaults to `true` for
     * single selection and `false` for multiple selection (upstream).
     */
    closeOnSelect?: boolean;
    /** Focuses the combo box and opens its options on render. */
    autoFocus?: boolean;
    /**
     * Option highlighted when the list opens, or an ember-power-select
     * `defaultHighlighted` function. By default nothing is highlighted
     * until the arrow keys are used (upstream), except single selection's
     * option when the list is opened by clicking.
     */
    defaultHighlighted?: any;
    /** Makes the options list as wide as the input. */
    matchTriggerWidth?: boolean;
    /** `tabindex` of the search input. */
    tabindex?: number;
    /** Opens the options list on render. */
    initiallyOpen?: boolean;
    /** Horizontal alignment of the options list: `'auto'`, `'left'`, `'right'` or `'center'`. */
    horizontalPosition?: string;
    /** Vertical position of the options list: `'auto'`, `'above'` or `'below'`. */
    verticalPosition?: string;
    /** Id of the element the options list renders into. */
    destination?: string;
    /** Prevents the page from scrolling while the options list is open. */
    preventScroll?: boolean;
    /**
     * Message when no option matches the search (or when there are no
     * options). Defaults to upstream's "{searchValue} doesn't match any
     * options" / "There aren't any options available".
     */
    noMatchesMessage?: string;
    /** @deprecated Has no effect; the "no matches" / "add" option is built in. */
    noMatchesMessageComponent?: any;
    /** Extra class for the element wrapping the options. */
    optionsClass?: string;
    /**
     * Height in px of each option in the (virtualized) list. Set it when the
     * block renders taller options. `'auto'` turns virtualization off so
     * long options wrap onto several lines (slower for long lists; no
     * truncation). Defaults to 29.
     */
    rowHeight?: number | 'auto';
    /**
     * Hides the options list: the combo box only takes typed values
     * (`@onCreateOption`, added with Enter), and has no dropdown icon.
     */
    noSuggestions?: boolean;
    /**
     * A character separating several values in the typed or pasted text,
     * typically `','`. Typing it adds the text before it; Enter (or leaving
     * the combo box) adds each value of pasted text.
     */
    delimiter?: string;
    /** Matches options case-sensitively. */
    isCaseSensitive?: boolean;
    /**
     * `'startsWith'` lists the matches starting with the search text first;
     * `'none'` keeps the options' order. Defaults to `'none'`.
     */
    sortMatchesBy?: EuiComboBoxSortMatchesBy;
    /**
     * Truncation of long option texts, any `EuiTextTruncate` argument but
     * `text` (e.g. `{ truncation: 'middle' }`). Options can override it
     * with their own `truncationProps`. While searching, the text is
     * truncated around the match instead. Defaults to CSS truncation at
     * the end.
     */
    truncationProps?: EuiComboBoxTruncationProps;
    /**
     * Text, a component, or an array of them before the input, e.g. a
     * label. Only shown with `@singleSelection` (upstream), so pills never
     * wrap onto taller rows.
     */
    prepend?: EuiComboBoxNode | EuiComboBoxNode[];
    /** Like `@prepend`, after the input. Only with `@singleSelection`. */
    append?: EuiComboBoxNode | EuiComboBoxNode[];
    /**
     * Custom matching for local filtering: `(option, searchText) => -1` for
     * no match, anything else for a match. Defaults to upstream's matching
     * (the label includes the search text, ignoring case unless
     * `@isCaseSensitive`).
     */
    matcher?: (option: any, searchText: string) => number;
    /**
     * Upstream's custom matching, used before `@matcher`:
     * `({ option, searchValue, normalizedSearchValue, isCaseSensitive }) =>
     * boolean`.
     */
    optionMatcher?: EuiComboBoxOptionMatcher;
    /**
     * The options are already filtered for the search text (e.g. loaded
     * from a server in `@onSearchChange`): they are listed as they are,
     * without the selected options.
     */
    async?: boolean;
    /**
     * Called whenever the search text changes, with the text and whether
     * any option matches it.
     */
    onSearchChange?: (searchValue: string, hasMatchingOptions?: boolean) => void;
    /** Shows a "return" badge on the highlighted option. */
    onFocusBadge?: boolean;
    /** Matching used when typing while the list is closed. */
    typeAheadOptionMatcher?: (option: any, searchText: string) => number;
    /** Icon in the input, anything `EuiIcon`'s `@type` accepts. */
    triggerIcon?: any;
    /** Called when a selected option's pill is removed. */
    removeTag?: (option: any) => void;
    /** Called on every input with the text and the select API. */
    onInput?: (text: string, select: any, event: Event) => any;
    /**
     * Called on keydown (with the select API and the event) before the
     * combo box handles the key; return `false` to prevent that.
     */
    onKeydown?: (select: any, event: KeyboardEvent) => any;
    /** Called with ember-power-select's API (`actions.open()`, `search`, …). */
    registerApi?: (select: any) => void;
    /** Custom positioning of the options list, see ember-basic-dropdown. */
    calculatePosition?: (...args: any[]) => any;
    /** Event that opens the list: `'click'` or `'mousedown'`. */
    eventType?: string;
    /** Accessible label of the combo box. */
    ariaLabel?: string;
    /** Id of the element labelling the combo box. */
    ariaLabelledBy?: string;
    /** Marks the combo box as required for assistive technology. */
    required?: boolean;
    /** `role` of the search input. Defaults to `combobox`. */
    triggerRole?: string;
    /** `title` of the combo box. */
    title?: string;
    /** Id of the input, e.g. for an `EuiFormRow`'s label. */
    triggerId?: string;
  };
  Blocks: {
    /**
     * Renders each option (in the list and in the pills), with its index
     * and the search text (upstream `renderOption`): `as |option i search|`
     * → `<EuiHighlight @text={{option.label}} @search={{search}} />`. In
     * pills the second value is the select API and the search is empty.
     * Optional: without a block, options show their text (strings, or
     * `@searchField` / `label` of objects), with the search text highlighted
     * in the list like upstream. Option `prepend` / `append` render around
     * the block.
     */
    default: [any, number | Select, string];
  };
}

interface Sliceable<T> {
  slice(): T[];
}

const isSliceable = <T,>(coll: any): coll is Sliceable<T> => {
  return isArray(coll);
};

export const toPlainArray = <T,>(collection: T[] | Sliceable<T>): T[] => {
  if (isSliceable<T>(collection)) {
    return collection.slice();
  } else {
    return collection;
  }
};

/**
 * Upstream `EuiInputPopover`: the options list stacks 2000 (`levels.menu`)
 * above its anchor's z-index, so it clears modals and flyouts it opens in
 * while tooltips (`levels.toast`) stay above it on the page.
 */
export const COMBO_BOX_LIST_Z_INDEX_OFFSET = 2000;

/** The parts of ember-power-select's API the container blur uses. */
type ContainerBlurApi = Select & {
  uniqueId?: string;
  isOpen?: boolean;
  highlighted?: unknown;
  actions: {
    close?: (e?: Event) => void;
    highlight?: (option: unknown) => void;
  };
};

export default class EuiComboBoxComponent extends Component<EuiComboBoxSignature> {
  @service declare euiI18n: EuiI18n;

  // UI state only: everything else is derived from the arguments

  /** ember-power-select's API (open state, highlighted option, …). */
  @tracked select: any = null;

  /**
   * The search text, as typed (upstream `searchValue`). Kept apart from
   * `select`, which is replaced on every highlight change: options derived
   * from it would re-run ember-power-select's options modifier, which
   * resets the highlight, in a loop.
   */
  @tracked searchValue = '';

  /** The options list's z-index, measured from the anchor when it opens. */
  @tracked listZIndex = COMBO_BOX_LIST_Z_INDEX_OFFSET;

  /** The combo box has focus (upstream `hasFocus`). */
  @tracked hasFocus = false;

  /** The search input itself has focus (the screen reader instructions). */
  @tracked inputHasFocus = false;

  /** The value `@options` resolved to, when it is a promise. */
  @tracked private settledOptions?: { promise: unknown; value: unknown };

  private watchedPromises = new WeakSet<object>();

  /** The last search text given to `@onSearchChange`. */
  private notifiedSearch = '';

  /**
   * The option to highlight next: after adding one (upstream moves the
   * active option to the next one), or the selected option when single
   * selection opens on click.
   */
  private pendingHighlight?:
    | { index: number; added: unknown }
    | { selected: unknown };

  get loadingMessage() {
    return (
      this.args.loadingMessage ||
      this.euiI18n.lookupToken(
        'euiComboBox.loadingMessage',
        'Loading options...'
      )
    );
  }

  get noMatchesMessage() {
    return (
      this.args.noMatchesMessage ||
      this.euiI18n.lookupToken(
        'euiComboBox.noMatchesMessage',
        'No results found'
      )
    );
  }

  get searchMessage() {
    return (
      this.args.searchMessage ||
      this.euiI18n.lookupToken('euiComboBox.searchMessage', 'Type to search')
    );
  }

  get alwaysShowCreateOption() {
    return this.args.onCreateOption && this.args.alwaysShowCreateOption;
  }

  /**
   * Upstream `euiComboBoxStyles` on the root (power-select's trigger):
   * relative, full width up to the form width (or 100% with `@fullWidth`).
   */
  @cached
  get rootClass(): string {
    const context = getEuiThemeContext(this);
    const form = useEuiBorealisStyles(context, euiFormVariables);

    return euiClass(
      context,
      comboBoxBoxReset,
      euiComboBoxStyles.euiComboBox,
      this.args.fullWidth
        ? euiComboBoxStyles.fullWidth
        : { maxInlineSize: form.maxWidth }
    );
  }

  /**
   * The options list panel (ember-basic-dropdown's content): upstream
   * `EuiInputPopover` (`panelPaddingSize="s"`, attached to the input), i.e.
   * an `EuiPanel` (plain, radius m) composed with the popover panel styles
   * in one class. The attached shadow follows the side the list opened on.
   */
  @cached
  get panelClass(): string {
    const context = getEuiThemeContext(this);
    const upstream = context.upstream;
    const panel = useEuiBorealisStyles(context, euiPanelStyles);
    const popover = useEuiBorealisStyles(context, euiPopoverPanelStyles);
    const colorMode = upstream.colorMode === 'DARK' ? 'dark' : 'light';

    return euiClass(
      context,
      // no React global reset; the portal also leaves the provider's color
      // wrapper, so the panel sets the theme's text color itself
      {
        boxSizing: 'border-box',
        color: upstream.euiTheme.colors.textParagraph,
        textAlign: 'start',
        '--ember-basic-dropdown-content-background-color':
          'var(--euiPopoverBackgroundColor)'
      },
      panel.euiPanel,
      panel.grow,
      panel.radius.m,
      { padding: euiPaddingSize(upstream, 's') ?? 0 },
      { backgroundColor: euiBackgroundColor(upstream, 'plain') },
      upstream.highContrastMode && {
        border: upstream.euiTheme.border.thin,
        borderColor: euiBorderColor(upstream, 'plain')
      },
      popover.euiPopover__panel,
      popover[colorMode],
      popover.isOpen,
      popover.isAttached.isAttached,
      popover.isAttached.bottom,
      { '&.ember-basic-dropdown-content--above': popover.isAttached.top },
      // ember-power-select's result count announcement
      `& .ember-power-select-visually-hidden{${euiScreenReaderOnly()}}`
    );
  }

  get listZIndexClass(): string {
    return euiClass(getEuiThemeContext(this), {
      '--ember-basic-dropdown-content-z-index': String(this.listZIndex)
    });
  }

  get dropdownClass(): string {
    return [
      'euiPanel euiPanel--plain euiPopover__panel',
      this.panelClass,
      this.listZIndexClass,
      this.args.dropdownClass
    ]
      .filter(Boolean)
      .join(' ');
  }


  /**
   * `@options`, or what it resolved to when it is a promise (`undefined`
   * while it is pending).
   */
  get sourceOptions(): unknown[] | undefined {
    const options = this.args.options as unknown;

    if (isPromiseLike(options)) {
      if (this.settledOptions?.promise === options) {
        return toList(this.settledOptions.value);
      }

      this.watchPromise(options);

      return undefined;
    }

    return toList(options);
  }

  private watchPromise(promise: PromiseLike<unknown>) {
    if (this.watchedPromises.has(promise as object)) return;

    this.watchedPromises.add(promise as object);

    const settle = (value: unknown) => {
      if (this.isDestroying || this.isDestroyed) return;
      // only the latest `@options` counts
      if (this.args.options !== (promise as unknown)) return;

      this.settledOptions = { promise, value };
    };

    promise.then(settle, () => settle([]));
  }

  /** `@options` is a promise that has not resolved yet. */
  get optionsPending(): boolean {
    return this.sourceOptions === undefined;
  }

  @cached
  get selectedOptions(): unknown[] {
    return toList(this.args.selectedOptions);
  }

  /**
   * `@optionMatcher` (upstream), else `@matcher` (ember-power-select's
   * `(option, searchText) => index`), else upstream's partial string
   * matcher: the label includes the search text, ignoring case unless
   * `@isCaseSensitive`.
   */
  @cached
  get optionMatcher(): EuiComboBoxOptionMatcher {
    const { optionMatcher, matcher, searchField } = this.args;

    if (optionMatcher) return optionMatcher;

    if (matcher) {
      return ({ option, searchValue }) => matcher(option, searchValue) >= 0;
    }

    return createPartialStringEqualityOptionMatcher(searchField);
  }

  /** Upstream `getMatchingOptions` (with group titles) for a search text. */
  matchingEntriesFor(
    searchValue: string,
    selectedOptions: readonly unknown[] = this.selectedOptions
  ): unknown[] {
    const { async, isCaseSensitive, search, searchField, singleSelection } =
      this.args;

    return getMatchingEntries({
      options: this.sourceOptions ?? [],
      selectedOptions,
      searchValue,
      optionMatcher: this.optionMatcher,
      searchField,
      isCaseSensitive,
      // `@async` options (and `@search` results) are already filtered
      isPreFiltered: Boolean(async || search),
      showPrevSelected: Boolean(singleSelection),
      sortMatchesBy: this.args.sortMatchesBy
    });
  }

  @cached
  get matchingEntries(): unknown[] {
    return this.matchingEntriesFor(this.searchValue);
  }

  /**
   * What the list shows, derived on every change of `@options`,
   * `@selectedOptions` and the search text (upstream `matchingOptions`):
   * the matches, without the selected options in multiple selection, as
   * ember-power-select options. Neither `@options` nor its options are
   * copied or changed.
   */
  @cached
  get powerSelectOptions(): unknown[] {
    return entriesToPowerSelectOptions(this.matchingEntries);
  }

  /**
   * `@search`, with its results filtered like `@options` (selected options
   * removed in multiple selection, `@sortMatchesBy`).
   */
  @cached
  get search(): EuiComboBoxSignature['Args']['search'] {
    const search = this.args.search;

    if (!search) return undefined;

    return (term: string, select: Select) => {
      const results = search(term, select) as unknown;
      const strip = (list: unknown) =>
        entriesToPowerSelectOptions(
          getMatchingEntries({
            options: toList(list),
            selectedOptions: this.selectedOptions,
            searchValue: term,
            optionMatcher: this.optionMatcher,
            searchField: this.args.searchField,
            isCaseSensitive: this.args.isCaseSensitive,
            isPreFiltered: true,
            showPrevSelected: Boolean(this.args.singleSelection),
            sortMatchesBy: this.args.sortMatchesBy
          })
        );

      if (isPromiseLike(results)) {
        const stripped = Promise.resolve(results).then(strip) as Promise<
          unknown[]
        > & { cancel?: () => void };
        const cancel = (results as { cancel?: () => void }).cancel;

        // ember-power-select cancels pending ember-concurrency searches
        if (typeof cancel === 'function') {
          stripped.cancel = () => cancel.call(results);
        }

        return stripped as unknown as PromiseProxy<any[]>;
      }

      return strip(results);
    };
  }

  /** Upstream `areAllOptionsSelected` (never with `@async` options). */
  get areAllOptionsSelected(): boolean {
    if (this.args.async || this.args.search) return false;

    const options = flattenOptionGroups(this.sourceOptions ?? []);

    return (
      options.length > 0 &&
      options.every((option) =>
        isComboBoxOptionSelected(
          option,
          this.selectedOptions,
          this.args.searchField,
          this.args.isCaseSensitive
        )
      )
    );
  }

  /**
   * Upstream empty states of the list: the search does not match, there
   * are no options, or all of them are selected.
   */
  get emptyStateMessage(): ReturnType<typeof htmlSafe> | string {
    const search = this.searchValue;
    const custom = this.args.noMatchesMessage;

    if (search) {
      return (
        custom ??
        this.i18nHtml(
          'euiComboBoxOptionsList.noMatchingOptions',
          "{searchValue} doesn't match any options",
          { searchValue: strong(search) }
        )
      );
    }

    if (!(this.sourceOptions ?? []).length && !this.args.search) {
      return (
        custom ??
        this.euiI18n.lookupToken(
          'euiComboBoxOptionsList.noAvailableOptions',
          "There aren't any options available"
        )
      );
    }

    if (this.areAllOptionsSelected) {
      return this.euiI18n.lookupToken(
        'euiComboBoxOptionsList.allOptionsSelected',
        "You've selected all available options"
      );
    }

    return this.noMatchesMessage;
  }

  /**
   * Upstream: with `@onCreateOption`, text equal to a selected option is
   * not offered again ("… has already been added").
   */
  get alreadyAddedMessage(): ReturnType<typeof htmlSafe> | undefined {
    const search = this.searchValue;

    if (!search || !this.args.onCreateOption) return undefined;
    if (this.args.delimiter && search.includes(this.args.delimiter)) {
      return undefined;
    }

    const selected = selectedOptionForSearchValue(
      this.selectedOptions,
      search,
      this.args.searchField,
      this.args.isCaseSensitive
    );

    if (selected === undefined) return undefined;

    return this.i18nHtml(
      'euiComboBoxOptionsList.alreadyAdded',
      '{label} has already been added',
      { label: strong(comboBoxOptionLabel(selected, this.args.searchField)) }
    );
  }

  private i18nHtml(
    token: string,
    fallback: string,
    values: Record<string, string>
  ): ReturnType<typeof htmlSafe> {
    const text = this.euiI18n.lookupToken(token, fallback, values) as unknown;

    return htmlSafe(
      isHTMLSafe(text) ? (text as { toString(): string }).toString() : String(text)
    );
  }

  /** The list shows a spinner: `@isLoading`, or `@options` still loading. */
  get isLoadingOptions(): boolean {
    return Boolean(this.args.isLoading) || this.optionsPending;
  }

  /**
   * Upstream: leftover text marks the combo box invalid once the list
   * closes or it loses focus (it was not added).
   */
  get markAsInvalid(): boolean {
    if (this.args.isInvalid) return true;
    if (!this.searchValue) return false;

    return !this.hasFocus || (!this.args.noSuggestions && !this.select?.isOpen);
  }

  /** Upstream closes the list after a choice only with single selection. */
  get closeOnSelect(): boolean {
    return this.args.closeOnSelect ?? Boolean(this.args.singleSelection);
  }

  /**
   * Upstream's screen reader instructions, read (politely) while the input
   * has focus.
   */
  get screenReaderInstructions(): string | undefined {
    if (!this.inputHasFocus) return undefined;

    const { placeholder } = this.args;
    const search = this.searchValue;
    const selected = this.selectedOptions;
    const value = selected
      .map((option) => comboBoxOptionLabel(option, this.args.searchField))
      .join(', ');
    const last = selected[selected.length - 1];

    return (
      `Combo box. Selected. ${search ? `${search}. Selected. ` : ''}${
        selected.length > 0
          ? `${value}. Press Backspace to delete ${comboBoxOptionLabel(
              last,
              this.args.searchField
            )}. `
          : ''
      }Combo box input. ${placeholder ? `${placeholder}.` : ''} Type some text or, to display a list of choices, press Down Arrow. ` +
      'To exit the list of choices, press Escape.'
    );
  }

  get listboxAriaLabel(): string {
    return this.euiI18n.lookupToken(
      'euiComboBox.listboxAriaLabel',
      'Choose from the following options'
    );
  }

  /** Untracked: the first measured option row shares its width (upstream). */
  optionWidth?: number;

  setOptionWidth = (width: number) => {
    this.optionWidth = width;
  };

  /** EuiComboBox's `@truncationProps` merged with the option's own. */
  truncationFor = (option: unknown): EuiComboBoxTruncationProps | undefined => {
    const own =
      option && typeof option === 'object'
        ? (option as EuiComboBoxOptionOption).truncationProps
        : undefined;

    if (!this.args.truncationProps && !own) return undefined;

    return { ...this.args.truncationProps, ...own };
  };

  labelFor = (option: unknown) =>
    comboBoxOptionLabel(option, this.args.searchField);

  /** Options rows yield their index; pills yield the select API. */
  isOptionRow = (index: unknown) => typeof index === 'number';

  /** ember-power-select must not filter the matches again. */
  matchAll = () => 0;

  <template>
    {{! @glint-nocheck: not typesafe yet }}

    <PowerSelect
      @multiple={{true}}
      ...attributes
      @onChange={{this.onChange}}
      @onFocus={{this.onFocus}}
      @onBlur={{this.onBlur}}
      @onOpen={{this.onOpen}}
      @onClose={{this.onClose}}
      @placeholderComponent={{@placeholderComponent}}
      @searchMessage={{this.searchMessage}}
      @searchMessageComponent={{if
        @searchMessageComponent
        @searchMessageComponent
        EuiComboBoxSearchMessage
      }}
      @noMatchesMessage={{this.noMatchesMessage}}
      @matchTriggerWidth={{@matchTriggerWidth}}
      @options={{this.powerSelectOptions}}
      @selected={{@selectedOptions}}
      @closeOnSelect={{this.closeOnSelect}}
      @defaultHighlighted={{if
        @defaultHighlighted
        @defaultHighlighted
        this.defaultHighlighted
      }}
      @highlightOnHover={{false}}
      @searchField={{@searchField}}
      @searchEnabled={{argOrDefault @searchEnabled true}}
      @tabindex={{if (argOrDefault @searchEnabled true) "-1" @tabindex}}
      @initiallyOpened={{and (not @isDisabled) @autoFocus (not @noSuggestions)}}
      @triggerComponent={{component
        EuiComboBoxTrigger
        fullWidth=@fullWidth
        compressed=@compressed
        isInvalid=this.markAsInvalid
        singleSelection=@singleSelection
        onClose=@removeTag
        isLoading=@isLoading
        autoFocus=(and (not @isDisabled) @autoFocus)
        icon=@triggerIcon
        prepend=@prepend
        append=@append
        noSuggestions=@noSuggestions
        inputTabindex=@tabindex
        inputRole=@triggerRole
        inputAriaLabel=@ariaLabel
        inputAriaLabelledBy=@ariaLabelledBy
        inputRequired=@required
        onClear=this.clearSelectedOptions
        onToggleList=this.onToggleListClick
        onToggleBlur=this.onToggleBlur
        onToggleKeydown=this.onToggleKeydown
        onPlainTextClick=this.onPlainTextClick
        screenReaderInstructions=this.screenReaderInstructions
      }}
      @matcher={{this.matchAll}}
      @initiallyOpen={{@initiallyOpen}}
      @typeAheadOptionMatcher={{@typeAheadOptionMatcher}}
      @buildSelection={{this.buildSelection}}
      @search={{this.search}}
      @onInput={{this.onInput}}
      @onKeydown={{this.onKeydown}}
      @scrollTo={{this.scrollTo}}
      @registerAPI={{queue this.registerAPI (optional @registerApi)}}
      @horizontalPosition={{@horizontalPosition}}
      @destination={{@destination}}
      @preventScroll={{@preventScroll}}
      @renderInPlace={{@renderInPlace}}
      @verticalPosition={{@verticalPosition}}
      @disabled={{@isDisabled}}
      @calculatePosition={{@calculatePosition}}
      @eventType={{@eventType}}
      @ariaLabel={{unless (argOrDefault @searchEnabled true) @ariaLabel}}
      @ariaLabelledBy={{unless
        (argOrDefault @searchEnabled true)
        @ariaLabelledBy
      }}
      @required={{unless (argOrDefault @searchEnabled true) @required}}
      @triggerRole={{if
        (argOrDefault @searchEnabled true)
        "presentation"
        @triggerRole
      }}
      @title={{@title}}
      @triggerId={{@triggerId}}
      @allowClear={{and (argOrDefault @isClearable true) (not @isDisabled)}}
      @loadingMessage={{this.loadingMessage}}
      @selectedItemComponent={{@selectedItemComponent}}
      @beforeOptionsComponent={{@beforeOptionsComponent}}
      @afterOptionsComponent={{if
        @afterOptionsComponent
        @afterOptionsComponent
        (if
          (and
            @onCreateOption
            (not this.select.loading)
            (not this.isLoadingOptions)
            this.searchValue
            this.alwaysShowCreateOption
            (not this.alreadyAddedMessage)
          )
          (component
            EuiComboBoxCreateOption
            customOptionText=@customOptionText
            onCreateOption=this.onCreateOption
            select=this.select
            alwaysShow=true
            delimiter=@delimiter
          )
        )
      }}
      @placeholder={{@placeholder}}
      @searchPlaceholder={{@searchPlaceholder}}
      @optionsComponent={{component
        EuiComboBoxOptions
        rowHeight=@rowHeight
        truncationProps=@truncationProps
        class=@optionsClass
        singleSelection=(if @singleSelection true false)
        selectedOptions=this.selectedOptions
        searchField=@searchField
        isLoading=this.isLoadingOptions
        onFocusBadge=@onFocusBadge
        listboxAriaLabel=this.listboxAriaLabel
      }}
      @extra={{@extra}}
      @groupComponent={{component EuiComboBoxGroup}}
      @triggerClass={{classNames
        "euiComboBox"
        this.rootClass
        (if @isDisabled "euiComboBox-isDisabled")
        (if this.markAsInvalid "euiComboBox-isInvalid")
        (if this.select.isOpen "euiComboBox-isOpen")
      }}
      @noMatchesMessageComponent={{if
        this.isLoadingOptions
        (component
          EuiComboBoxOptions
          isLoading=true
          loadingMessage=this.loadingMessage
        )
        (if
          (and
            @onCreateOption
            this.searchValue
            (not this.alwaysShowCreateOption)
            (not this.alreadyAddedMessage)
          )
          (component
            EuiComboBoxCreateOption
            customOptionText=@customOptionText
            onCreateOption=this.onCreateOption
            select=this.select
            alwaysShow=false
            delimiter=@delimiter
          )
          (component
            EuiComboBoxNoMatchesMessage
            message=(if
              this.alreadyAddedMessage
              this.alreadyAddedMessage
              this.emptyStateMessage
            )
          )
        )
      }}
      @dropdownClass={{this.dropdownClass}}
      as |option i|
    >
      {{#if (has-block)}}
        {{yield option i (if (this.isOptionRow i) this.searchValue "")}}
      {{else if (this.isOptionRow i)}}
        <EuiComboBoxOptionText
          @text={{this.labelFor option}}
          @search={{this.searchValue}}
          @isCaseSensitive={{@isCaseSensitive}}
          @rowHeight={{@rowHeight}}
          @truncationProps={{this.truncationFor option}}
          @width={{this.optionWidth}}
          @onResize={{this.setOptionWidth}}
        />
      {{else}}
        {{this.labelFor option}}
      {{/if}}
    </PowerSelect>
  </template>

  /** Keeps the highlighted option in view in the virtualized list. */
  @action
  scrollTo(option: any, select: { results: unknown[]; uniqueId: string }): void {
    const optionsList = document.querySelector(
      `[data-combo-box-list="${select.uniqueId}"]`
    ) as HTMLElement;

    if (!optionsList) {
      return;
    }

    const index = flattenComboBoxRows(toList(select.results)).indexOf(option);

    if (index === -1) {
      return;
    }

    const optionElement = optionsList.querySelector(
      `[data-option-index="${index}"]`
    ) as HTMLElement;

    if (!optionElement) {
      return;
    }

    const optionTopScroll = optionElement.offsetTop;
    const optionBottomScroll = optionTopScroll + optionElement.offsetHeight;

    if (optionBottomScroll > optionsList.offsetHeight + optionsList.scrollTop) {
      optionsList.scrollTop = optionBottomScroll - optionsList.offsetHeight;
    } else if (optionTopScroll < optionsList.scrollTop) {
      optionsList.scrollTop = optionTopScroll;
    }
  }

  @action
  registerAPI(select: Select) {
    this.select = select;

    // ember-power-select may change the search itself (e.g. after a choice)
    this.updateSearchValue(
      (select as { searchText?: string })?.searchText ?? ''
    );
  }

  /** Keeps `searchValue` in step and tells `@onSearchChange`. */
  updateSearchValue(value: string) {
    if (value !== this.searchValue) this.searchValue = value;

    if (value === this.notifiedSearch) return;

    this.notifiedSearch = value;

    const onSearchChange = this.args.onSearchChange;

    if (onSearchChange) {
      const hasMatchingOptions = this.matchingEntriesFor(value).some(
        (entry) => !isComboBoxGroupLabel(entry)
      );

      onSearchChange(value, hasMatchingOptions);
    }
  }

  /** Upstream `clearSearchValue`. */
  clearSearch() {
    this.select?.actions.search('');
    this.updateSearchValue('');
  }

  /**
   * Upstream `activeOptionIndex` rules, as ember-power-select's
   * `defaultHighlighted`: nothing is highlighted when the list opens (the
   * selected option when single selection opens on click), the highlight
   * stays while its option is listed, and after adding an option it moves
   * to the next one.
   */
  defaultHighlighted = ({
    results,
    highlighted
  }: {
    results: unknown[];
    highlighted: unknown;
  }): unknown => {
    const { rows, selectable } = selectableRows(toList(results));
    const pending = this.pendingHighlight;

    if (pending && 'selected' in pending) {
      this.pendingHighlight = undefined;

      return rows.find(
        (row, index) =>
          selectable[index] &&
          isComboBoxOptionChecked(
            row,
            [pending.selected],
            this.args.searchField
          )
      );
    }

    if (pending) {
      const remainingIndexes = rows
        .map((_, index) => index)
        .filter((index) => rows[index] !== pending.added);

      // the added option left the list: the move is done
      if (remainingIndexes.length === rows.length) {
        this.pendingHighlight = undefined;
      }

      const next = findNextSelectableIndex(
        remainingIndexes,
        (i) => selectable[remainingIndexes[i]!] === true,
        Math.max(0, Math.min(pending.index, remainingIndexes.length - 1))
      );

      return next === -1 ? undefined : rows[remainingIndexes[next]!];
    }

    if (highlighted !== undefined && rows.includes(highlighted)) {
      return highlighted;
    }

    return undefined;
  };

  @action
  onChange(selected: any[]) {
    if (this.args.singleSelection) {
      // keep only the option that was just chosen
      this.args.onChange(
        selected.length > 0 ? [selected[selected.length - 1]] : []
      );

      return;
    }

    this.args.onChange(selected);
  }

  @action
  onOpen(select: Select, event: Event): boolean | void {
    // upstream `noSuggestions`: the list never opens
    if (this.args.noSuggestions) return false;

    // ember-power-select calls it with its API first
    const onOpen = this.args.onOpen as
      | ((select: Select, event: Event) => boolean | void)
      | undefined;

    const result = onOpen?.(select, event);

    if (result === false) return false;

    const trigger = document.querySelector<HTMLElement>(
      `[data-ebd-id="${(select as unknown as { uniqueId: string }).uniqueId}-trigger"]`
    );
    this.listZIndex =
      (trigger ? getElementZIndex(trigger, document.body) : 0) +
      COMBO_BOX_LIST_Z_INDEX_OFFSET;

    // upstream `onComboBoxClick`: single selection highlights its option
    const selected = this.selectedOptions[0];

    if (
      this.args.singleSelection &&
      selected !== undefined &&
      event &&
      /^(mouse|pointer|touch|click)/.test(event.type)
    ) {
      this.pendingHighlight = { selected };
    }

    return result;
  }

  @action
  onClose(select: Select, event: Event): boolean | void {
    const onClose = this.args.onClose as
      | ((select: Select, event: Event) => boolean | void)
      | undefined;
    const result = onClose?.(select, event);

    if (result !== false) this.pendingHighlight = undefined;

    return result;
  }

  /** Upstream `onComboBoxFocus`: focusing the input opens the list. */
  @action
  onFocus(select: Select, event: FocusEvent): void {
    (this.args.onFocus as ((...args: unknown[]) => void) | undefined)?.(
      select,
      event
    );

    this.hasFocus = true;
    this.inputHasFocus = true;

    const api = (this.select ?? select) as Select & {
      isOpen?: boolean;
      actions: { open?: () => void };
    };

    if (!this.args.isDisabled && !this.args.noSuggestions && !api?.isOpen) {
      api?.actions.open?.();
    }
  }

  /**
   * Typing `@delimiter` adds the text before it (upstream
   * `onSearchChange`), and clears the input.
   */
  @action
  onInput(term: string, select: Select, event: Event): string | false | void {
    const corrected = this.args.onInput?.(term, select, event);

    if (corrected === false) return false;

    const text = typeof corrected === 'string' ? corrected : term;
    const delimiter = this.args.delimiter;

    this.updateSearchValue(text);

    if (delimiter && text.endsWith(delimiter) && this.setCustomOptions(text)) {
      const input = event?.target as HTMLInputElement | null;

      if (input && 'value' in input) input.value = '';

      return '';
    }

    return corrected as string | void;
  }

  /**
   * Upstream `onKeyDown`: arrows move through the options (wrapping), Enter
   * chooses the highlighted option or adds the typed text, Escape closes
   * the list, and Tab is held while an option is highlighted.
   */
  @action
  onKeydown(select: Select, event: KeyboardEvent): boolean | void {
    if (this.args.onKeydown?.(select, event) === false) return false;
    if (this.args.isDisabled) return;

    const target = event.target as HTMLElement | null;

    // only the search input's own keys (not the clear or pill buttons')
    if (!target?.classList.contains('euiComboBox__input')) return;

    const api = (this.select ?? select) as Select & {
      isOpen: boolean;
      highlighted: unknown;
      results: unknown[];
      actions: {
        highlight: (option: unknown) => void;
        scrollTo: (option: unknown) => void;
        close: (e?: Event) => void;
      };
    };
    const hasActiveOption = api.isOpen && api.highlighted !== undefined;

    switch (event.key) {
      case 'ArrowUp':
      case 'ArrowDown': {
        if (!api.isOpen) return; // ember-power-select opens the list

        event.preventDefault();
        event.stopPropagation();

        const next = this.nextActiveOption(
          api.results,
          api.highlighted,
          event.key === 'ArrowDown' ? 1 : -1
        );

        if (next !== undefined) {
          api.actions.highlight(next);
          api.actions.scrollTo(next);
        }

        return false;
      }

      case 'Escape':
        if (!api.isOpen) return;

        event.preventDefault();
        event.stopPropagation();
        api.actions.close(event);

        return false;

      case 'Enter':
        event.preventDefault();
        event.stopPropagation();

        // ember-power-select chooses the highlighted option
        if (hasActiveOption) return;

        this.setCustomOptions(this.searchValue);

        return false;

      case 'Tab':
        // no tabbing away while navigating the options
        if (hasActiveOption) {
          event.preventDefault();
          event.stopPropagation();

          return false;
        }

        return;

      case 'Backspace':
        // upstream: a plain text input edits its text (the selection's
        // label) as usual, and the selection goes
        if (this.asPlainText) {
          this.onPlainTextBackspace(target as HTMLInputElement);

          return;
        }

        // deleting text works as usual (and opens the list)
        if ((target as HTMLInputElement).value?.length) return;

        this.onBackspace(event);

        return false;
    }
  }

  /**
   * Upstream's container `onKeyDown` while the toggle button has focus
   * (after a click on it): arrows open the list or move through it, Escape
   * closes it, Tab is held while an option is highlighted. Enter and Space
   * press the button (its native click). Returns whether the key must not
   * reach ember-basic-dropdown / ember-power-select's trigger handlers
   * (which would toggle, choose or type ahead).
   */
  @action
  onToggleKeydown(event: KeyboardEvent): boolean {
    const api = this.select as
      | (Select & {
          isOpen: boolean;
          highlighted: unknown;
          results: unknown[];
          actions: {
            open: (e?: Event) => void;
            highlight: (option: unknown) => void;
            scrollTo: (option: unknown) => void;
            close: (e?: Event) => void;
          };
        })
      | undefined;

    if (!api || this.args.isDisabled) return true;
    if (this.args.onKeydown?.(api, event) === false) return true;

    switch (event.key) {
      case 'ArrowUp':
      case 'ArrowDown': {
        event.preventDefault();

        if (!api.isOpen) {
          if (!this.args.noSuggestions) api.actions.open(event);

          return true;
        }

        const next = this.nextActiveOption(
          api.results,
          api.highlighted,
          event.key === 'ArrowDown' ? 1 : -1
        );

        if (next !== undefined) {
          api.actions.highlight(next);
          api.actions.scrollTo(next);
        }

        return true;
      }

      case 'Escape':
        if (!api.isOpen) return false;

        event.preventDefault();
        api.actions.close(event);

        return true;

      case 'Tab':
        if (api.isOpen && api.highlighted !== undefined) {
          event.preventDefault();

          return true;
        }

        return false;

      default:
        return true;
    }
  }

  /** Upstream `incrementActiveOptionIndex`. */
  nextActiveOption(
    results: unknown[],
    highlighted: unknown,
    direction: 1 | -1
  ): unknown {
    const { rows, selectable } = selectableRows(toList(results));

    if (!rows.length) return undefined;

    const active = highlighted === undefined ? -1 : rows.indexOf(highlighted);
    const start =
      active < 0
        ? direction < 0
          ? rows.length - 1
          : 0
        : (active + direction + rows.length) % rows.length;
    const index = findNextSelectableIndex(
      rows,
      (i) => selectable[i] === true,
      start,
      direction
    );

    return index === -1 ? undefined : rows[index];
  }

  /** `@singleSelection` is `{ asPlainText: true }`. */
  get asPlainText(): boolean {
    const single = this.args.singleSelection;

    return Boolean(single && typeof single === 'object' && single.asPlainText);
  }

  /**
   * Upstream Backspace in an empty input: removes the last selection (and
   * reopens single selection's list).
   */
  @action
  onBackspace(event: KeyboardEvent): void {
    const selected = this.selectedOptions;
    const select = this.select;

    if (!selected.length || !select) return;

    const last = selected[selected.length - 1];

    event.preventDefault();
    this.args.onChange(selected.filter((option) => option !== last));
    this.pendingHighlight = undefined;

    if (this.args.singleSelection && !select.isOpen) {
      select.actions.open?.(event);
    }
  }

  /**
   * Upstream plain text Backspace: the input's text (the selection's label
   * while nothing is typed) becomes the search text, and the selection is
   * removed; the key then deletes a character as usual.
   */
  onPlainTextBackspace(input: HTMLInputElement): void {
    const text = input.value ?? '';

    this.select?.actions.search(text);
    this.updateSearchValue(text);

    const selected = this.selectedOptions;

    if (selected.length) {
      this.args.onChange(
        selected.filter((option) => option !== selected[selected.length - 1])
      );
      this.pendingHighlight = undefined;
    }
  }

  /** Upstream: clicking a plain text input runs the focus handler again. */
  @action
  onPlainTextClick(event: MouseEvent): void {
    this.onFocus(this.select, event as unknown as FocusEvent);
  }

  /**
   * Upstream toggle button: `closeList` while open, else
   * `onOpenListClick` (focus the input and open the list).
   */
  @action
  onToggleListClick(): void {
    const select = this.select;

    if (!select || this.args.isDisabled) return;

    if (select.isOpen) {
      select.actions.close?.();

      return;
    }

    document
      .getElementById(
        `ember-power-select-trigger-multiple-input-${select.uniqueId}`
      )
      ?.focus();

    if (!this.select?.isOpen && !this.args.noSuggestions) {
      this.select?.actions.open?.();
    }
  }

  /** Upstream `clearSelectedOptions`: empties the selection, focuses the input. */
  @action
  clearSelectedOptions(event?: Event): void {
    event?.stopPropagation();
    this.args.onChange([]);

    const input = document.getElementById(
      `ember-power-select-trigger-multiple-input-${this.select?.uniqueId}`
    );

    // focusing opens the list (upstream opens it too)
    input?.focus();

    if (this.select && !this.select.isOpen && !this.args.noSuggestions) {
      this.select.actions.open?.();
    }
  }

  /**
   * Upstream `onContainerBlur`: leaving the combo box closes the list and
   * adds the typed text (`@onCreateOption`, or the option it names), so it
   * does not look like a text input. Text that is not added stays, and
   * marks the combo box invalid.
   */
  @action
  onBlur(select: Select, event: FocusEvent): void {
    this.inputHasFocus = false;
    this.containerBlur((this.select ?? select) as ContainerBlurApi, event);
  }

  /**
   * Upstream `onContainerBlur` for the toggle button, which takes focus when
   * pressed: leaving the combo box from it closes the list as from the
   * input.
   */
  @action
  onToggleBlur(event: FocusEvent): void {
    if (this.select) this.containerBlur(this.select as ContainerBlurApi, event);
  }

  /**
   * Upstream `onContainerBlur`: focus moving into the list stays; focus
   * moving elsewhere in the combo box (the toggle or clear button, a pill's
   * remove button) clears the active option; leaving calls `@onBlur`,
   * closes the list and adds the typed text.
   */
  containerBlur(api: ContainerBlurApi | undefined, event?: FocusEvent): void {
    const next = event?.relatedTarget as Node | null;
    const list = api?.uniqueId
      ? document.getElementById(`ember-basic-dropdown-content-${api.uniqueId}`)
      : null;
    const root = (event?.target as HTMLElement | null)?.closest(
      '.euiComboBox'
    );

    if (next && list?.contains(next)) return;

    if (next && root?.contains(next)) {
      if (api?.highlighted !== undefined) api.actions.highlight?.(undefined);

      return;
    }

    (this.args.onBlur as ((...args: unknown[]) => void) | undefined)?.(
      api,
      event
    );

    const hasActiveOption = Boolean(
      api?.isOpen && api.highlighted !== undefined
    );

    this.hasFocus = false;

    if (api?.isOpen) api.actions.close?.(event);

    if (!hasActiveOption && this.searchValue) {
      this.setCustomOptions(this.searchValue, true);
    }
  }

  /** The "add" option. */
  @action
  onCreateOption() {
    this.setCustomOptions(this.searchValue);
  }

  /**
   * Upstream `setCustomOptions`: the text, or each value separated by
   * `@delimiter` (trimmed, without duplicates), is added. Returns whether
   * anything was added.
   */
  setCustomOptions(text: string, isContainerBlur = false): boolean {
    const delimiter = this.args.delimiter;
    const values = delimiter
      ? [...new Set(text.split(delimiter).map((value) => value.trim()))]
      : [text];
    let seen = this.args.selectedOptions;
    let selection = toList(seen);
    let added = false;

    values.forEach((value) => {
      if (!value.length) return;

      // the consumer may have updated `@selectedOptions` already
      if (this.args.selectedOptions !== seen) {
        seen = this.args.selectedOptions;
        selection = toList(seen);
      }

      const result = this.addCustomOption(value, selection, isContainerBlur);

      if (result === false) return;

      added = true;

      if (result) selection = result;
    });

    return added;
  }

  /**
   * Upstream `addCustomOption` for one value: the only matching option
   * when its label equals the value, else `@onCreateOption` unless an
   * option with that label is selected. Returns the new selection when an
   * existing option was chosen, `false` when nothing was added.
   */
  addCustomOption(
    value: string,
    selection: unknown[],
    isContainerBlur: boolean
  ): unknown[] | false | void {
    const { isCaseSensitive, searchField, singleSelection } = this.args;
    const matched = this.onlyMatchingOption(value, selection);

    if (matched !== undefined) {
      if ((matched as { disabled?: boolean } | null)?.disabled) return false;

      const next = singleSelection ? [matched] : [...selection, matched];

      this.onAddOption(matched, next, isContainerBlur);

      return next;
    }

    if (!this.args.onCreateOption || !value) return false;

    if (
      selectedOptionForSearchValue(
        selection,
        value,
        searchField,
        isCaseSensitive
      ) !== undefined
    ) {
      return false;
    }

    const created = this.args.onCreateOption(
      value,
      flattenOptionGroups(this.sourceOptions ?? [])
    );

    // the consumer rejects a custom option explicitly
    if (created === false) return false;

    this.clearSearch();

    // a custom single selection closes the list
    if (singleSelection) this.select?.actions.close();
  }

  /**
   * Upstream `onAddOption` for an option chosen by its text: single
   * selection closes the list, multiple selection keeps it open with the
   * next option highlighted.
   */
  onAddOption(option: unknown, next: unknown[], isContainerBlur: boolean) {
    const { rows } = selectableRows(toList(this.select?.results));
    const index = rows.indexOf(option);

    this.args.onChange(next);
    this.clearSearch();

    if (this.args.singleSelection) {
      this.select?.actions.close();
    } else if (!isContainerBlur && index > -1) {
      this.pendingHighlight = { index, added: option };
    }
  }

  /**
   * Upstream `doesSearchMatchOnlyOption`: the value matches exactly one
   * (unselected) option, and equals its label.
   */
  onlyMatchingOption(value: string, selection: unknown[]): unknown {
    const { isCaseSensitive, searchField } = this.args;
    const matches = this.matchingEntriesFor(value, selection).filter(
      (entry) => !isComboBoxGroupLabel(entry)
    );

    if (matches.length !== 1) return undefined;

    const [option] = matches;

    return transformForCaseSensitivity(
      comboBoxOptionLabel(option, searchField),
      isCaseSensitive
    ) === transformForCaseSensitivity(value, isCaseSensitive)
      ? option
      : undefined;
  }

  /**
   * ember-power-select's choice: adds the option (single selection: makes
   * it the selection; a chosen option is never deselected from the list,
   * like upstream). Removing a pill passes a selected option: it is
   * removed.
   */
  @action
  buildSelection(option: any, select: Select) {
    const current = toList(select.selected);
    const index = current.findIndex((item) => isEqual(item, option));

    if (this.args.singleSelection) {
      if (index > -1 && current.length === 1) return current;

      this.clearSearch();

      return [option];
    }

    if (index > -1) {
      return current.filter((_, i) => i !== index);
    }

    const { rows } = selectableRows(
      toList((select as unknown as { results?: unknown[] }).results)
    );
    const at = rows.indexOf(option);

    if (at > -1) this.pendingHighlight = { index: at, added: option };

    this.clearSearch();

    return [...current, option];
  }
}

/** A list from an array, an Ember array or nothing (never the same array). */
function toList(collection: unknown): unknown[] {
  if (!collection) return [];
  if (Array.isArray(collection)) return collection;
  if (isArray(collection)) {
    return (collection as unknown as { slice(): unknown[] }).slice();
  }

  return [];
}

function isPromiseLike(value: unknown): value is PromiseLike<unknown> {
  return Boolean(
    value &&
      (typeof value === 'object' || typeof value === 'function') &&
      typeof (value as { then?: unknown }).then === 'function'
  );
}

/** Escaped user text in bold, for i18n messages rendered as HTML. */
function strong(text: string): string {
  return `<strong>${text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')}</strong>`;
}

/**
 * The rows of ember-power-select results (groups, then their options) and
 * which can be highlighted: options that are not disabled, in groups that
 * are not disabled.
 */
function selectableRows(results: unknown[]): {
  rows: unknown[];
  selectable: boolean[];
} {
  const rows: unknown[] = [];
  const selectable: boolean[] = [];
  const disabled = (value: unknown) =>
    Boolean(
      value &&
        typeof value === 'object' &&
        (value as { disabled?: boolean }).disabled === true
    );

  results.forEach((entry) => {
    if (emberPowerSelectIsGroup(entry)) {
      const group = entry as unknown as { options: unknown[] };

      rows.push(entry);
      selectable.push(false);
      group.options.forEach((child) => {
        rows.push(child);
        selectable.push(!disabled(entry) && !disabled(child));
      });
    } else {
      rows.push(entry);
      selectable.push(!disabled(entry));
    }
  });

  return { rows, selectable };
}
