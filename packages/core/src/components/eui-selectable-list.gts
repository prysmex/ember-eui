import Component from '@glimmer/component';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { modifier } from 'ember-modifier';

import cssStyle from '../-private/css-style.ts';
import EuiHighlight from './eui-highlight.gts';
import EuiSelectableListItem from './eui-selectable-list-item.gts';

import { toggleOption } from '../-private/selectable-options.ts';

import type { EuiSelectableOption } from '../-private/selectable-options.ts';

export type { EuiSelectableOption };

const MAX_VISIBLE_OPTIONS = 7;

/**
 * The list of an `EuiSelectable`: renders the options, checks and
 * unchecks them on click, and scrolls the keyboard's current option into
 * view. Usually rendered for you by `EuiSelectable`.
 */
export interface EuiSelectableListSignature {
  Element: HTMLDivElement;
  Args: {
    /** All options; `@onOptionClick` gets them with the change applied. */
    options: EuiSelectableOption[];
    /** The options to show (e.g. those matching a search). Defaults to all. */
    visibleOptions?: EuiSelectableOption[];
    /** The search, highlighted in the labels. */
    searchValue?: string;
    /** Index (in the visible options) of the keyboard's current option. */
    activeOptionIndex?: number;
    /** Called when an option is pressed, to make it the current one. */
    setActiveOptionIndex?: (index: number) => void;
    /** Called with all options after one is checked or unchecked. */
    onOptionClick: (options: EuiSelectableOption[]) => void;
    /**
     * `true`: one option at most; `'always'`: exactly one (it cannot be
     * unchecked).
     */
    singleSelection?: boolean | 'always';
    /** Pressing a checked option excludes it (`checked: 'off'`) first. */
    allowExclusions?: boolean;
    /** Shows the check mark column. Defaults to `true`. */
    showIcons?: boolean;
    /**
     * Shows the "return key" badge on the current option: `true`, `false`
     * or `{ text, iconSide }`. Defaults to `true`.
     */
    onFocusBadge?: boolean | { text?: string; iconSide?: 'left' | 'right' };
    /** Adds a border around the list. */
    bordered?: boolean;
    /** Height of each option in px. Defaults to `32`. */
    rowHeight?: number;
    /**
     * Height of the list in px, or `'full'` to fill its container. By
     * default it shows up to 7 options (and half of the next one).
     */
    height?: number | 'full';
    /** `id` of the `<ul role="listbox">`. */
    listId?: string;
    /** Id of each option's `<li>`, for `aria-activedescendant`. */
    makeOptionId?: (index: number) => string;
    /** The list is driven from a search field (which keeps focus). */
    searchable?: boolean;
    /** @private Whether `<:option>` is given (when blocks are forwarded). */
    hasOption?: boolean;
    /** @private Whether `<:optionPrepend>` is given. */
    hasOptionPrepend?: boolean;
    /** @private Whether `<:optionAppend>` is given. */
    hasOptionAppend?: boolean;
  };
  Blocks: {
    /** Renders an option's label yourself; yields the option and the search. */
    option: [option: EuiSelectableOption, searchValue: string];
    /** Content before each label (e.g. an icon); yields the option. */
    optionPrepend: [option: EuiSelectableOption];
    /** Content after each label (e.g. a badge); yields the option. */
    optionAppend: [option: EuiSelectableOption];
  };
}

export default class EuiSelectableList extends Component<EuiSelectableListSignature> {
  get optionArray(): EuiSelectableOption[] {
    return this.args.visibleOptions ?? this.args.options;
  }

  get rowHeight(): number {
    return this.args.rowHeight ?? 32;
  }

  get isFullHeight(): boolean {
    return this.args.height === 'full';
  }

  get listHeight(): number | undefined {
    if (this.isFullHeight) return undefined;
    if (typeof this.args.height === 'number') return this.args.height;

    const count = this.optionArray.length;

    // show half of the last one to hint there is more to scroll to
    return count > MAX_VISIBLE_OPTIONS
      ? (MAX_VISIBLE_OPTIONS - 0.5) * this.rowHeight
      : count * this.rowHeight;
  }

  get classes(): string {
    return [
      'euiSelectableList',
      this.isFullHeight && 'euiSelectableList-fullHeight',
      this.args.bordered && 'euiSelectableList-bordered'
    ]
      .filter(Boolean)
      .join(' ');
  }

  get isMultiSelectable(): boolean {
    return !this.args.searchable && !this.args.singleSelection;
  }

  get groupLabelCount(): number {
    return this.optionArray.filter((option) => option.isGroupLabel).length;
  }

  optionId = (index: number): string | undefined => this.args.makeOptionId?.(index);

  isFocused = (index: number): boolean => this.args.activeOptionIndex === index;

  posInSet = (index: number): number => index + 1 - this.groupLabelCount;

  @action
  onOptionMouseDown(index: number): void {
    this.args.setActiveOptionIndex?.(index);
  }

  @action
  onOptionClick(option: EuiSelectableOption): void {
    this.toggleOption(option);
  }

  toggleOption(option: EuiSelectableOption): void {
    const options = toggleOption(this.args.options, option, {
      allowExclusions: this.args.allowExclusions,
      singleSelection: this.args.singleSelection
    });

    if (options) this.args.onOptionClick(options);
  }

  /** Keeps the keyboard's current option in view. */
  scrollActiveIntoView = modifier((list: HTMLElement, [index]: [number | undefined]) => {
    if (index === undefined || index < 0) return;

    const item = list.querySelectorAll<HTMLElement>(':scope > ul > li')[index];

    item?.scrollIntoView?.({ block: 'nearest' });
  });

  <template>
    <div class={{this.classes}} ...attributes>
      <div
        class="euiSelectableList__list"
        tabindex="-1"
        style={{cssStyle
          (hash height=this.listHeight overflowY="auto" position="relative")
        }}
        {{this.scrollActiveIntoView @activeOptionIndex}}
      >
        <ul
          id={{@listId}}
          role="listbox"
          tabindex={{unless @searchable "0"}}
          aria-multiselectable={{if this.isMultiSelectable "true"}}
        >
          {{#let
            (flag @hasOption (has-block "option"))
            (flag @hasOptionPrepend (has-block "optionPrepend"))
            (flag @hasOptionAppend (has-block "optionAppend"))
            as |customOption customPrepend customAppend|
          }}
          {{#each this.optionArray as |option index|}}
            {{#if option.isGroupLabel}}
              <li
                role="presentation"
                class="euiSelectableList__groupLabel"
                style={{cssStyle (hash height=this.rowHeight)}}
              >{{option.prepend}}{{option.label}}{{option.append}}</li>
            {{else}}
              <EuiSelectableListItem
                id={{this.optionId index}}
                class={{option.className}}
                style={{cssStyle (hash height=this.rowHeight)}}
                title={{if option.searchableLabel option.searchableLabel option.label}}
                aria-posinset={{this.posInSet index}}
                aria-setsize={{sub this.optionArray.length this.groupLabelCount}}
                @isFocused={{this.isFocused index}}
                @checked={{option.checked}}
                @disabled={{option.disabled}}
                @hasPrepend={{or2 customPrepend option.prepend}}
                @hasAppend={{or2 customAppend option.append}}
                @showIcons={{@showIcons}}
                @onFocusBadge={{@onFocusBadge}}
                @allowExclusions={{@allowExclusions}}
                {{on "mousedown" (fn this.onOptionMouseDown index)}}
                {{on "click" (fn this.onOptionClick option)}}
              >
                <:default>
                  {{#if customOption}}
                    {{yield option (if @searchValue @searchValue "") to="option"}}
                  {{else}}
                    <EuiHighlight @text={{option.label}} @search={{@searchValue}} />
                  {{/if}}
                </:default>
                <:prepend>
                  {{~#if customPrepend}}{{yield option to="optionPrepend"}}{{else}}{{option.prepend}}{{/if~}}
                </:prepend>
                <:append>
                  {{~#if customAppend}}{{yield option to="optionAppend"}}{{else}}{{option.append}}{{/if~}}
                </:append>
              </EuiSelectableListItem>
            {{/if}}
          {{/each}}
          {{/let}}
        </ul>
      </div>
    </div>
  </template>
}

// an explicit flag (blocks forwarded by EuiSelectable) or the block itself
function flag(explicit: boolean | undefined, hasBlock: boolean): boolean {
  return explicit ?? hasBlock;
}

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}

function sub(a: number, b: number): number {
  return a - b;
}
