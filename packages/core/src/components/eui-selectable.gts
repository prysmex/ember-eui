import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { schedule } from '@ember/runloop';
import { service } from '@ember/service';
import { isDestroying, isDestroyed } from '@ember/destroyable';

import cssStyle from '../-private/css-style.ts';
import { randomId } from '../-private/random-id.ts';
import {
  createPartialStringEqualityOptionMatcher,
  getMatchingOptions,
  isNavigable,
  toggleOptionWithChange
} from '../-private/selectable-options.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiSelectableStyles } from '../utils/eui/styles.generated.ts';
import { euiClass } from '../utils/eui/styles.ts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiScreenReaderLive from './eui-screen-reader-live.gts';
import EuiSelectableList from './eui-selectable-list.gts';
import EuiSelectableMessage from './eui-selectable-message.gts';
import EuiSelectableSearch from './eui-selectable-search.gts';
import EuiSpacer from './eui-spacer.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiCss } from '../utils/eui/styles.ts';
import type {
  EuiSelectableOption,
  EuiSelectableOptionMatcher,
  EuiSelectableOptionMatcherArgs,
  EuiSelectableToolTipProps,
  EuiSelectableTruncationProps
} from '../-private/selectable-options.ts';
import type Owner from '@ember/owner';
import type { ComponentLike } from '@glint/template';

export type {
  EuiSelectableOption,
  EuiSelectableOptionMatcher,
  EuiSelectableOptionMatcherArgs,
  EuiSelectableToolTipProps,
  EuiSelectableTruncationProps
};
export { createPartialStringEqualityOptionMatcher };

/** Upstream default matcher (module scope: one instance). */
const DEFAULT_OPTION_MATCHER = createPartialStringEqualityOptionMatcher();

interface OptionBlocks {
  /** Renders an option's label yourself; yields the option and the search. */
  option: [option: EuiSelectableOption, searchValue: string];
  /** Content before each label (e.g. an icon); yields the option. */
  optionPrepend: [option: EuiSelectableOption];
  /** Content after each label (e.g. a badge); yields the option. */
  optionAppend: [option: EuiSelectableOption];
}

/**
 * A list of options to pick one or several from, optionally with a search
 * field. It is the building block of pickers: put it in a popover for a
 * filter menu, or in a panel for a "choose fields" list. Options are
 * `{ label, checked }` objects; `@onChange` gets them all back with the
 * change applied.
 */
export interface EuiSelectableSignature {
  Element: HTMLDivElement;
  Args: {
    /** The options: `{ label, checked, disabled, isGroupLabel, prepend, append }`. */
    options: EuiSelectableOption[];
    /**
     * Called with all options after one is checked or unchecked (new
     * objects; the given ones are not mutated), the click or keyboard
     * event, and the changed option.
     */
    onChange?: (
      options: EuiSelectableOption[],
      event: Event | undefined,
      changedOption: EuiSelectableOption
    ) => void;
    /**
     * Called with the current option (or `null`) whenever it changes
     * through the keyboard, focus or searching.
     */
    onActiveOptionChange?: (option: EuiSelectableOption | null) => void;
    /** Adds a search field that filters the options. */
    searchable?: boolean;
    /**
     * Options of the search field: `{ placeholder, compressed, isLoading,
     * isClearable, value, defaultValue, onChange(searchValue,
     * matchingOptions), onSearch (same as onChange, not called on render),
     * onKeyDown, onKeyUpCapture, onInput, onClick, onFocus, onBlur,
     * inputRef, className, prepend, append, 'data-test-subj' }`.
     * With `value` the search is controlled: update it from `onChange`.
     * `onChange` is also called once after the first render.
     */
    searchProps?: {
      placeholder?: string;
      compressed?: boolean;
      isLoading?: boolean;
      isClearable?: boolean;
      value?: string;
      defaultValue?: string;
      onChange?: (searchValue: string, matchingOptions: EuiSelectableOption[]) => void;
      onSearch?: (searchValue: string, matchingOptions: EuiSelectableOption[]) => void;
      onKeyDown?: (event: KeyboardEvent) => void;
      onClick?: (event: MouseEvent) => void;
      onFocus?: (event: FocusEvent) => void;
      onBlur?: (event: FocusEvent) => void;
      inputRef?: (input: HTMLInputElement) => void;
      'data-test-subj'?: string;
      /** Extra class name(s) of the search field. */
      className?: string;
      /** Content before the field: a string (a label) or a component. */
      prepend?: string | ComponentLike;
      /** Content after the field: a string (a label) or a component. */
      append?: string | ComponentLike;
      /** Called on `keyup` in the field, in the capture phase. */
      onKeyUpCapture?: (event: KeyboardEvent) => void;
      /** Called on `input` in the field, before the search is updated. */
      onInput?: (event: Event) => void;
    };
    /**
     * Decides whether an option matches the search: `({ option,
     * searchValue, normalizedSearchValue }) => boolean`. Defaults to the
     * label (or `searchableLabel`) containing the search, ignoring case.
     */
    optionMatcher?: EuiSelectableOptionMatcher;
    /**
     * Screen reader text read before the keyboard instructions of the
     * search field.
     */
    selectableScreenReaderText?: string;
    /**
     * `true`: one option at most; `'always'`: exactly one (clicking the
     * checked option keeps it); `false`: several, shown with check boxes
     * and `aria-checked`. Defaults to `false`.
     */
    singleSelection?: boolean | 'always';
    /** Pressing a checked option excludes it (`checked: 'off'`, a cross). */
    allowExclusions?: boolean;
    /** Shows a loading message instead of the list. */
    isLoading?: boolean;
    /**
     * The options are already filtered (e.g. by a server): the search does
     * not filter. `{ highlightSearch: false }` also turns off highlighting
     * the search in the labels.
     */
    isPreFiltered?: boolean | { highlightSearch?: boolean };
    /** Height of the list in px, or `'full'` to fill the container. */
    height?: number | 'full';
    /**
     * Options of the list: `{ bordered, paddingSize, showIcons, rowHeight,
     * onFocusBadge, isVirtualized, textWrap, truncationProps, css }`
     * (`onFocusBadge` defaults to `false`, upstream). See
     * `EuiSelectableList`.
     */
    listProps?: {
      bordered?: boolean;
      paddingSize?: 'none' | 's';
      showIcons?: boolean;
      rowHeight?: number;
      onFocusBadge?: boolean | { text?: string; iconSide?: 'left' | 'right' };
      isVirtualized?: boolean;
      textWrap?: 'truncate' | 'wrap';
      truncationProps?: EuiSelectableTruncationProps;
      css?: EuiCss;
    };
    /** Message while `@isLoading`. Defaults to "Loading options". */
    loadingMessage?: string;
    /** Message when the search matches nothing. */
    noMatchesMessage?: string;
    /** Message when there are no options. Defaults to "No options available". */
    emptyMessage?: string;
    /**
     * Error message shown instead of the list (before any other message)
     * when not `null` / `undefined`.
     */
    errorMessage?: string | null;
    /**
     * Styles composed last into the root's class (upstream's `css` prop),
     * e.g. from a template built on EuiSelectable.
     */
    css?: EuiCss;
  };
  Blocks: {
    /**
     * Lays out the parts yourself: yields `{ list, search }` components,
     * e.g. `as |parts|` → `<parts.search />` … `<parts.list />`. Without
     * it, the search (if any) comes above the list.
     */
    default: [
      {
        list: ComponentLike<{
          Element: HTMLDivElement;
          Args: {
            /** @private Minimum height (px) of the message replacing the list. */
            messageMinHeight?: number;
          };
          Blocks: OptionBlocks;
        }>;
        search: ComponentLike<{ Element: HTMLInputElement }> | undefined;
      }
    ];
  } & OptionBlocks;
}

export default class EuiSelectable extends Component<EuiSelectableSignature> {
  @service declare euiI18n: EuiI18n;

  /** The uncontrolled search (UI state); `searchProps.value` wins. */
  @tracked internalSearchValue = '';
  /** The keyboard's current option (UI state), see `activeOptionIndex`. */
  @tracked internalActiveOptionIndex?: number;
  @tracked isFocused = false;

  rootId = `euiSelectable_${randomId()}`;
  preventOnFocus = false;

  constructor(owner: Owner, args: EuiSelectableSignature['Args']) {
    super(owner, args);
    const { searchProps } = args;

    this.internalSearchValue =
      searchProps?.value || String(searchProps?.defaultValue || '');

    // a single selected option starts as the current one
    const checked = args.options.filter((option) => option.checked);

    if (args.singleSelection && checked.length === 1) {
      const index = this.visibleOptions.indexOf(checked[0]!);

      if (index !== -1) this.internalActiveOptionIndex = index;
    }

    // upstream reports the initial search on mount; after render so the
    // callback may update state that was already rendered
    if (searchProps?.onChange) {
      schedule('afterRender', () => {
        if (isDestroying(this) || isDestroyed(this)) return;
        this.args.searchProps?.onChange?.(this.searchValue, this.visibleOptions);
      });
    }
  }

  /** `searchProps.value` (controlled) or the typed search. */
  get searchValue(): string {
    return this.args.searchProps?.value ?? this.internalSearchValue;
  }

  get optionMatcher(): EuiSelectableOptionMatcher {
    return this.args.optionMatcher ?? DEFAULT_OPTION_MATCHER;
  }

  /** Derived from `@options` and the search on every change (no copy kept). */
  @cached
  get visibleOptions(): EuiSelectableOption[] {
    return getMatchingOptions(
      this.args.options,
      this.searchValue,
      this.args.isPreFiltered,
      this.optionMatcher
    );
  }

  /**
   * The current option's index in the visible options; dropped when the
   * options change and it is out of range (upstream).
   */
  get activeOptionIndex(): number | undefined {
    const index = this.internalActiveOptionIndex;

    return index !== undefined && index >= this.visibleOptions.length ? undefined : index;
  }

  /** Sets the current option and reports it (upstream `onActiveOptionChange`). */
  setActive(index: number | undefined): void {
    if (index === this.internalActiveOptionIndex) return;

    const previous = this.activeOptionIndex;

    this.internalActiveOptionIndex = index;

    if (this.activeOptionIndex !== previous) {
      const option = index !== undefined && index >= 0 ? this.visibleOptions[index] : undefined;

      this.args.onActiveOptionChange?.(option ?? null);
    }
  }

  get listId(): string {
    return `${this.rootId}_listbox`;
  }

  get messageId(): string {
    return `${this.rootId}_messageContent`;
  }

  get instructionsId(): string {
    return `${this.rootId}_instructions`;
  }

  /** Upstream default: multiple selection. */
  get singleSelection(): boolean | 'always' {
    return this.args.singleSelection ?? false;
  }

  get screenReaderInstructions(): string {
    const instructions = this.euiI18n.lookupToken(
      'euiSelectable.screenReaderInstructions',
      'Use the Up and Down arrow keys to move focus over options. Press Enter to select. Press Escape to collapse options.'
    );
    const custom = this.args.selectableScreenReaderText;

    return custom ? `${custom} ${instructions}` : instructions;
  }

  /** Upstream live region text: "N results available". */
  get searchResultsText(): string {
    const resultsLength = this.visibleOptions.filter(
      (option) => !option.disabled || option.hasAriaDisabled
    ).length;

    return this.euiI18n.lookupToken(
      'euiSelectable.searchResults',
      ({ resultsLength }) =>
        `${resultsLength as number} result${resultsLength === 1 ? '' : 's'} available`,
      { resultsLength }
    );
  }

  @cached
  get classes(): string {
    return euiClass(
      getEuiThemeContext(this),
      euiSelectableStyles.euiSelectable,
      this.args.height === 'full' && euiSelectableStyles.fullHeight,
      this.args.css
    );
  }

  makeOptionId = (index: number): string => `${this.listId}_option-${index}`;

  get activeDescendant(): string | undefined {
    return this.activeOptionIndex === undefined ? undefined : this.makeOptionId(this.activeOptionIndex);
  }

  get placeholder(): string {
    return (
      this.args.searchProps?.placeholder ??
      this.euiI18n.lookupToken('euiSelectable.placeholderName', 'Filter options')
    );
  }

  get message(): { text?: string; isLoading?: boolean; searchValue?: string } | undefined {
    if (this.args.errorMessage != null) {
      return { text: this.args.errorMessage };
    }

    if (this.args.isLoading) {
      return {
        isLoading: true,
        text:
          this.args.loadingMessage ??
          this.euiI18n.lookupToken('euiSelectable.loadingOptions', 'Loading options')
      };
    }

    if (this.searchValue && this.visibleOptions.length === 0) {
      return this.args.noMatchesMessage
        ? { text: this.args.noMatchesMessage }
        : { searchValue: this.searchValue };
    }

    if (!this.args.options.length) {
      return {
        text:
          this.args.emptyMessage ??
          this.euiI18n.lookupToken('euiSelectable.noAvailableOptions', 'No options available')
      };
    }

    return undefined;
  }

  get noMatchesSuffix(): string {
    return this.euiI18n
      .lookupToken('euiSelectable.noMatchingOptions', "{searchValue} doesn't match any options", {
        searchValue: '\u0000'
      })
      .split('\u0000')
      .slice(1)
      .join('');
  }

  get noMatchesPrefix(): string {
    return this.euiI18n
      .lookupToken('euiSelectable.noMatchingOptions', "{searchValue} doesn't match any options", {
        searchValue: '\u0000'
      })
      .split('\u0000')[0]!;
  }

  /** Upstream: `hasAriaDisabled` options can be the current one. */
  isSelectable = (option: EuiSelectableOption | undefined): boolean =>
    isNavigable(option);

  /**
   * Upstream `isFocusOnSearchOrListBox`: keys pressed on other content
   * laid out inside (e.g. a footer button) are not list navigation. The
   * root itself also counts (Ember EUI: keydown dispatched on it).
   */
  isFromSearchOrList(event: Event): boolean {
    const target = event.target;

    if (target === event.currentTarget) return true;
    if (!(target instanceof Element)) return false;

    return (
      (this.args.searchable && target.classList.contains('euiSelectableSearch')) ||
      Boolean(target.closest('.euiSelectableList'))
    );
  }

  @action
  onMouseDown(): void {
    // a click on an option must not first move the current option
    this.preventOnFocus = true;
  }

  @action
  onFocus(): void {
    if (this.preventOnFocus) {
      this.preventOnFocus = false;

      return;
    }

    if (!this.visibleOptions.length || this.activeOptionIndex !== undefined) return;

    const firstChecked = this.visibleOptions.findIndex(
      (option) => option.checked && this.isSelectable(option)
    );

    this.setActive(
      firstChecked > -1 ? firstChecked : this.visibleOptions.findIndex(this.isSelectable)
    );
    this.isFocused = true;
  }

  @action
  onBlur(event: FocusEvent): void {
    const container = event.currentTarget as HTMLElement;

    if (event.relatedTarget && container.contains(event.relatedTarget as Node)) return;

    // Focus also leaves when rendering removes the focused list (e.g. the
    // options become empty): reset after that render, unless focus is back.
    schedule('actions', () => {
      if (isDestroying(this) || isDestroyed(this)) return;
      if (container.isConnected && container.contains(document.activeElement)) return;

      this.setActive(undefined);
      this.isFocused = false;
    });
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (!this.isFromSearchOrList(event)) {
      this.setActive(undefined);
      this.isFocused = false;

      return;
    }

    switch (event.key) {
      case 'Alt':
      case 'Shift':
      case 'Control':
      case 'Meta':
        break;
      case 'ArrowUp':
        event.preventDefault();
        event.stopPropagation();
        this.moveActiveOption(-1);
        break;
      case 'ArrowDown':
        event.preventDefault();
        event.stopPropagation();
        this.moveActiveOption(1);
        break;
      case ' ':
      case 'Enter': {
        // in a search field, Space types (upstream)
        if (
          event.key === ' ' &&
          this.args.searchable &&
          (event.target as HTMLElement).tagName === 'INPUT'
        )
          return;

        event.preventDefault();
        event.stopPropagation();

        const option =
          this.activeOptionIndex !== undefined
            ? this.visibleOptions[this.activeOptionIndex]
            : undefined;

        const result = option
          ? toggleOptionWithChange(this.args.options, option, {
              allowExclusions: this.args.allowExclusions,
              singleSelection: this.singleSelection
            })
          : undefined;

        if (result) this.args.onChange?.(result.options, event, result.changedOption);
        break;
      }
      default:
        // typing in the search: the current option is picked again
        this.setActive(undefined);
        break;
    }
  }

  moveActiveOption(amount: number): void {
    const options = this.visibleOptions;

    if (!options.length || !options.some(this.isSelectable)) return;

    const current = this.activeOptionIndex;
    let next =
      current === undefined || current < 0
        ? amount < 0
          ? options.length - 1
          : 0
        : (current + amount + options.length) % options.length;

    // skip group labels and disabled options
    while (!this.isSelectable(options[next])) {
      next = (next + (amount > 0 ? 1 : -1) + options.length) % options.length;
    }

    this.setActive(next);
  }

  @action
  onSearchChange(matchingOptions: EuiSelectableOption[], searchValue: string): void {
    this.internalSearchValue = searchValue;
    this.setActive(undefined);
    this.args.searchProps?.onChange?.(searchValue, matchingOptions);
    this.args.searchProps?.onSearch?.(searchValue, matchingOptions);

    if (this.isFocused) this.onFocus();
  }

  @action
  setActiveOptionIndex(index: number): void {
    this.setActive(index);
  }

  @action
  onOptionClick(
    options: EuiSelectableOption[],
    event: Event | undefined,
    changedOption: EuiSelectableOption
  ): void {
    this.args.onChange?.(options, event, changedOption);
  }

  <template>
    <div
      class="euiSelectable {{this.classes}}"
      {{on "keydown" this.onKeyDown}}
      {{on "focusin" this.onFocus}}
      {{on "focusout" this.onBlur}}
      {{on "mousedown" this.onMouseDown}}
      ...attributes
    >
      {{#let
        (if
          @searchable
          (component
            EuiSelectableSearch
            options=@options
            onChange=this.onSearchChange
            placeholder=this.placeholder
            value=this.searchValue
            compressed=@searchProps.compressed
            isLoading=@searchProps.isLoading
            isClearable=@searchProps.isClearable
            isPreFiltered=@isPreFiltered
            optionMatcher=this.optionMatcher
            listId=(if this.message undefined this.listId)
            ariaDescribedby=this.instructionsId
            ariaLabel=this.placeholder
            activeDescendant=this.activeDescendant
            instructions=this.screenReaderInstructions
            onKeyDown=@searchProps.onKeyDown
            onClick=@searchProps.onClick
            onFocus=@searchProps.onFocus
            onBlur=@searchProps.onBlur
            inputRef=@searchProps.inputRef
            dataTestSubj=(searchTestSubj @searchProps)
            className=@searchProps.className
            prepend=@searchProps.prepend
            append=@searchProps.append
            onKeyUpCapture=@searchProps.onKeyUpCapture
            onInput=@searchProps.onInput
          )
        )
        (component
          SelectableBody
          selectable=this
          options=@options
          searchable=@searchable
          singleSelection=this.singleSelection
          allowExclusions=@allowExclusions
          height=@height
          listProps=@listProps
          searchValue=this.searchValue
          activeOptionIndex=this.activeOptionIndex
          message=this.message
          searchResultsText=this.searchResultsText
          isPreFiltered=@isPreFiltered
        )
        as |Search List|
      }}
        {{#if (has-block)}}
          {{yield (hash list=List search=Search)}}
        {{else}}
          {{#if Search}}
            <Search />
          {{/if}}
          <List
            @hasOption={{has-block "option"}}
            @hasOptionPrepend={{has-block "optionPrepend"}}
            @hasOptionAppend={{has-block "optionAppend"}}
          >
            <:option as |option searchValue|>
              {{yield option searchValue to="option"}}
            </:option>
            <:optionPrepend as |option|>{{yield option to="optionPrepend"}}</:optionPrepend>
            <:optionAppend as |option|>{{yield option to="optionAppend"}}</:optionAppend>
          </List>
        {{/if}}
      {{/let}}
    </div>
  </template>
}

function flag(explicit: boolean | undefined, hasBlock: boolean): boolean {
  return explicit ?? hasBlock;
}

function searchTestSubj(
  searchProps: EuiSelectableSignature['Args']['searchProps']
): string | undefined {
  return searchProps?.['data-test-subj'];
}

interface SelectableBodySignature {
  Element: HTMLDivElement;
  Args: {
    selectable: EuiSelectable;
    options: EuiSelectableOption[];
    searchable?: boolean;
    singleSelection?: boolean | 'always';
    allowExclusions?: boolean;
    height?: number | 'full';
    listProps?: EuiSelectableSignature['Args']['listProps'];
    searchValue: string;
    activeOptionIndex?: number;
    message?: EuiSelectable['message'];
    /** "N results available", announced while searching. */
    searchResultsText?: string;
    isPreFiltered?: EuiSelectableSignature['Args']['isPreFiltered'];
    hasOption?: boolean;
    hasOptionPrepend?: boolean;
    hasOptionAppend?: boolean;
    /** @private Minimum height of the message (sitewide template: 300px). */
    messageMinHeight?: number;
  };
  Blocks: OptionBlocks;
}

/** The list, or the message replacing it (loading, no matches, empty). */
class SelectableBody extends Component<SelectableBodySignature> {
  get selectable(): EuiSelectable {
    return this.args.selectable;
  }

  /** Upstream: announces while a message shows or an option is current. */
  get isLiveActive(): boolean {
    return this.args.message !== undefined || this.args.activeOptionIndex !== undefined;
  }

  <template>
    {{#if @searchable}}
      <EuiScreenReaderLive @isActive={{this.isLiveActive}}>
        {{#if @message}}
          {{#if @message.searchValue}}
            {{this.selectable.noMatchesPrefix}}{{@message.searchValue}}{{this.selectable.noMatchesSuffix}}
          {{else}}
            {{@message.text}}
          {{/if}}
        {{else}}
          {{@searchResultsText}}
        {{/if}}
      </EuiScreenReaderLive>
    {{/if}}
    {{#if @message}}
      <EuiSelectableMessage
        id={{this.selectable.messageId}}
        style={{cssStyle (hash minHeight=@messageMinHeight)}}
        @bordered={{@listProps.bordered}}
        ...attributes
      >
        {{#if @message.isLoading}}
          <EuiLoadingSpinner @size="m" />
          <EuiSpacer @size="xs" />
        {{/if}}
        <p>
          {{#if @message.searchValue}}
            {{this.selectable.noMatchesPrefix}}<strong>{{@message.searchValue}}</strong>{{this.selectable.noMatchesSuffix}}
          {{else}}
            {{@message.text}}
          {{/if}}
        </p>
      </EuiSelectableMessage>
    {{else}}
      <EuiSelectableList
        @options={{@options}}
        @visibleOptions={{this.selectable.visibleOptions}}
        @searchValue={{@searchValue}}
        @activeOptionIndex={{@activeOptionIndex}}
        @setActiveOptionIndex={{this.selectable.setActiveOptionIndex}}
        @onOptionClick={{this.selectable.onOptionClick}}
        @singleSelection={{@singleSelection}}
        @allowExclusions={{@allowExclusions}}
        @searchable={{@searchable}}
        @height={{@height}}
        @bordered={{@listProps.bordered}}
        @paddingSize={{@listProps.paddingSize}}
        @showIcons={{@listProps.showIcons}}
        @rowHeight={{@listProps.rowHeight}}
        @onFocusBadge={{@listProps.onFocusBadge}}
        @isVirtualized={{@listProps.isVirtualized}}
        @textWrap={{@listProps.textWrap}}
        @truncationProps={{@listProps.truncationProps}}
        @isPreFiltered={{@isPreFiltered}}
        @css={{@listProps.css}}
        @listId={{this.selectable.listId}}
        @makeOptionId={{this.selectable.makeOptionId}}
        @hasOption={{flag @hasOption (has-block "option")}}
        @hasOptionPrepend={{flag @hasOptionPrepend (has-block "optionPrepend")}}
        @hasOptionAppend={{flag @hasOptionAppend (has-block "optionAppend")}}
        @ariaLabel={{if @searchable this.selectable.placeholder}}
        ...attributes
      >
        <:option as |option searchValue|>{{yield option searchValue to="option"}}</:option>
        <:optionPrepend as |option|>{{yield option to="optionPrepend"}}</:optionPrepend>
        <:optionAppend as |option|>{{yield option to="optionAppend"}}</:optionAppend>
      </EuiSelectableList>
    {{/if}}
  </template>
}
