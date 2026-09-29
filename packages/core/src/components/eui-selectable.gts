import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { randomId } from '../-private/random-id.ts';
import { getMatchingOptions, toggleOption } from '../-private/selectable-options.ts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiSelectableList from './eui-selectable-list.gts';
import EuiSelectableMessage from './eui-selectable-message.gts';
import EuiSelectableSearch from './eui-selectable-search.gts';
import EuiSpacer from './eui-spacer.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiSelectableOption } from '../-private/selectable-options.ts';
import type Owner from '@ember/owner';
import type { ComponentLike } from '@glint/template';

export type { EuiSelectableOption };

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
    /** Called with all options after one is checked or unchecked. */
    onChange?: (options: EuiSelectableOption[]) => void;
    /** Adds a search field that filters the options. */
    searchable?: boolean;
    /**
     * Options of the search field: `{ placeholder, compressed,
     * defaultValue, onSearch(searchValue, matchingOptions) }`.
     */
    searchProps?: {
      placeholder?: string;
      compressed?: boolean;
      defaultValue?: string;
      onSearch?: (searchValue: string, matchingOptions: EuiSelectableOption[]) => void;
    };
    /**
     * `true`: one option at most; `'always'`: exactly one (clicking the
     * checked option keeps it).
     */
    singleSelection?: boolean | 'always';
    /** Pressing a checked option excludes it (`checked: 'off'`, a cross). */
    allowExclusions?: boolean;
    /** Shows a loading message instead of the list. */
    isLoading?: boolean;
    /** The options are already filtered (e.g. by a server): the search does not filter. */
    isPreFiltered?: boolean;
    /** Height of the list in px, or `'full'` to fill the container. */
    height?: number | 'full';
    /**
     * Options of the list: `{ bordered, showIcons, rowHeight, onFocusBadge }`.
     */
    listProps?: {
      bordered?: boolean;
      showIcons?: boolean;
      rowHeight?: number;
      onFocusBadge?: boolean | { text?: string; iconSide?: 'left' | 'right' };
    };
    /** Message while `@isLoading`. Defaults to "Loading options". */
    loadingMessage?: string;
    /** Message when the search matches nothing. */
    noMatchesMessage?: string;
    /** Message when there are no options. Defaults to "No options available". */
    emptyMessage?: string;
  };
  Blocks: {
    /**
     * Lays out the parts yourself: yields `{ list, search }` components,
     * e.g. `as |parts|` → `<parts.search />` … `<parts.list />`. Without
     * it, the search (if any) comes above the list.
     */
    default: [
      {
        list: ComponentLike<{ Element: HTMLDivElement; Blocks: OptionBlocks }>;
        search: ComponentLike<{ Element: HTMLInputElement }> | undefined;
      }
    ];
  } & OptionBlocks;
}

export default class EuiSelectable extends Component<EuiSelectableSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked searchValue = '';
  @tracked activeOptionIndex?: number;
  @tracked isFocused = false;

  rootId = `euiSelectable_${randomId()}`;
  preventOnFocus = false;

  constructor(owner: Owner, args: EuiSelectableSignature['Args']) {
    super(owner, args);
    this.searchValue = args.searchProps?.defaultValue ?? '';

    // a single selected option starts as the current one
    const checked = args.options.filter((option) => option.checked);

    if (args.singleSelection && checked.length === 1) {
      const index = this.visibleOptions.indexOf(checked[0]!);

      if (index !== -1) this.activeOptionIndex = index;
    }
  }

  get visibleOptions(): EuiSelectableOption[] {
    return getMatchingOptions(this.args.options, this.searchValue, this.args.isPreFiltered);
  }

  get listId(): string {
    return `${this.rootId}_listbox`;
  }

  get messageId(): string {
    return `${this.rootId}_messageContent`;
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

  isSelectable = (option: EuiSelectableOption | undefined): boolean =>
    Boolean(option && !option.disabled && !option.isGroupLabel);

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

    if (!this.visibleOptions.length || this.activeOptionIndex) return;

    const firstChecked = this.visibleOptions.findIndex(
      (option) => option.checked && this.isSelectable(option)
    );

    this.activeOptionIndex =
      firstChecked > -1 ? firstChecked : this.visibleOptions.findIndex(this.isSelectable);
    this.isFocused = true;
  }

  @action
  onBlur(event: FocusEvent): void {
    const container = event.currentTarget as HTMLElement;

    if (event.relatedTarget && container.contains(event.relatedTarget as Node)) return;

    this.activeOptionIndex = undefined;
    this.isFocused = false;
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    switch (event.key) {
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
      case 'Enter': {
        event.preventDefault();
        event.stopPropagation();

        const option =
          this.activeOptionIndex !== undefined
            ? this.visibleOptions[this.activeOptionIndex]
            : undefined;

        const options = option
          ? toggleOption(this.args.options, option, {
              allowExclusions: this.args.allowExclusions,
              singleSelection: this.args.singleSelection
            })
          : undefined;

        if (options) this.args.onChange?.(options);
        break;
      }
      default:
        // typing in the search: the current option is picked again
        this.activeOptionIndex = undefined;
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

    this.activeOptionIndex = next;
  }

  @action
  onSearchChange(matchingOptions: EuiSelectableOption[], searchValue: string): void {
    this.searchValue = searchValue;
    this.activeOptionIndex = undefined;
    this.args.searchProps?.onSearch?.(searchValue, matchingOptions);

    if (this.isFocused) this.onFocus();
  }

  @action
  setActiveOptionIndex(index: number): void {
    this.activeOptionIndex = index;
  }

  @action
  onOptionClick(options: EuiSelectableOption[]): void {
    this.args.onChange?.(options);
  }

  <template>
    <div
      class="euiSelectable {{if (isFull @height) 'euiSelectable-fullHeight'}}"
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
            defaultValue=@searchProps.defaultValue
            compressed=@searchProps.compressed
            isPreFiltered=@isPreFiltered
            listId=(if this.message undefined this.listId)
          )
        )
        (component
          SelectableBody
          selectable=this
          options=@options
          searchable=@searchable
          singleSelection=@singleSelection
          allowExclusions=@allowExclusions
          height=@height
          listProps=@listProps
          searchValue=this.searchValue
          activeOptionIndex=this.activeOptionIndex
          message=this.message
        )
        as |Search List|
      }}
        {{#if (has-block)}}
          {{yield (hash list=List search=Search)}}
        {{else}}
          {{#if Search}}
            <Search
              aria-activedescendant={{this.activeDescendant}}
              aria-label={{this.placeholder}}
            />
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

function isFull(height: unknown): boolean {
  return height === 'full';
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
    hasOption?: boolean;
    hasOptionPrepend?: boolean;
    hasOptionAppend?: boolean;
  };
  Blocks: OptionBlocks;
}

/** The list, or the message replacing it (loading, no matches, empty). */
class SelectableBody extends Component<SelectableBodySignature> {
  get selectable(): EuiSelectable {
    return this.args.selectable;
  }

  <template>
    {{#if @message}}
      <EuiSelectableMessage
        id={{this.selectable.messageId}}
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
        @showIcons={{@listProps.showIcons}}
        @rowHeight={{@listProps.rowHeight}}
        @onFocusBadge={{@listProps.onFocusBadge}}
        @listId={{this.selectable.listId}}
        @makeOptionId={{this.selectable.makeOptionId}}
        @hasOption={{flag @hasOption (has-block "option")}}
        @hasOptionPrepend={{flag @hasOptionPrepend (has-block "optionPrepend")}}
        @hasOptionAppend={{flag @hasOptionAppend (has-block "optionAppend")}}
        aria-label={{if @searchable this.selectable.placeholder}}
        ...attributes
      >
        <:option as |option searchValue|>{{yield option searchValue to="option"}}</:option>
        <:optionPrepend as |option|>{{yield option to="optionPrepend"}}</:optionPrepend>
        <:optionAppend as |option|>{{yield option to="optionAppend"}}</:optionAppend>
      </EuiSelectableList>
    {{/if}}
  </template>
}
