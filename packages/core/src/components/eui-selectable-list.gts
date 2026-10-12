import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { modifier } from 'ember-modifier';

import cssStyle from '../-private/css-style.ts';
import { toggleOption } from '../-private/selectable-options.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiSelectableListGroupLabelStyles,
  euiSelectableListStyles
} from '../utils/eui/selectable.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiHighlight from './eui-highlight.gts';
import EuiSelectableListItem from './eui-selectable-list-item.gts';

import type { EuiSelectableOption } from '../-private/selectable-options.ts';

export type { EuiSelectableOption };

const MAX_VISIBLE_OPTIONS = 7;
// the extra 2 × 8px padding of a group label's divider line (upstream)
const GROUP_LABEL_DIVIDER = 16;

// Scoped stand-in for React's global list reset; upstream styles win.
const LIST_RESET = {
  ':where(&)': {
    boxSizing: 'border-box',
    margin: 0,
    padding: 0,
    listStyle: 'none'
  }
} as const;
const GROUP_LABEL_RESET = {
  ':where(&)': { boxSizing: 'border-box', margin: 0, listStyle: 'none' }
} as const;

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
     * unchecked); `false`: several, with check box indicators. Left
     * undefined, options look single (upstream EuiSelectableList) while the
     * listbox stays multiselectable; `EuiSelectable` passes `false`.
     */
    singleSelection?: boolean | 'always';
    /** Pressing a checked option excludes it (`checked: 'off'`) first. */
    allowExclusions?: boolean;
    /** Shows the selection indicator column. Defaults to `true`. */
    showIcons?: boolean;
    /**
     * Shows the "return key" badge on the current option: `true`, `false`
     * or `{ text, iconSide }`. Defaults to `false` (upstream).
     */
    onFocusBadge?: boolean | { text?: string; iconSide?: 'left' | 'right' };
    /** Adds a border around the list. */
    bordered?: boolean;
    /** `'s'` pads the list. Defaults to `'none'`. */
    paddingSize?: 'none' | 's';
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
    /** `aria-label` of the listbox. */
    ariaLabel?: string;
    /** `aria-describedby` of the listbox. */
    ariaDescribedby?: string;
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
  get context() {
    return getEuiThemeContext(this);
  }

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

  /** Upstream passes `singleSelection !== false` to each option. */
  get itemSingleSelection(): boolean {
    return this.args.singleSelection !== false;
  }

  get isMultiSelectable(): boolean {
    return (
      !this.args.searchable &&
      this.args.singleSelection !== true &&
      this.args.singleSelection !== 'always'
    );
  }

  get groupLabelCount(): number {
    return this.optionArray.filter((option) => option.isGroupLabel).length;
  }

  @cached
  get classes() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiSelectableListStyles);
    const groupLabel = useEuiBorealisStyles(
      context,
      euiSelectableListGroupLabelStyles
    );
    return {
      root: euiClass(
        context,
        { boxSizing: 'border-box' },
        styles.euiSelectableList,
        this.isFullHeight && styles.fullHeight,
        this.args.bordered && styles.bordered,
        this.args.paddingSize === 's' && styles.paddingSize.s
      ),
      list: euiClass(
        context,
        { boxSizing: 'border-box' },
        styles.euiSelectableList__list
      ),
      ul: euiClass(context, LIST_RESET),
      groupLabel: euiClass(context, GROUP_LABEL_RESET, groupLabel.groupLabel)
    };
  }

  optionId = (index: number): string | undefined => this.args.makeOptionId?.(index);

  isFocused = (index: number): boolean => this.args.activeOptionIndex === index;

  posInSet = (index: number): number =>
    this.optionArray.slice(0, index + 1).filter((option) => !option.isGroupLabel)
      .length;

  groupLabelHeight = (index: number): number =>
    this.rowHeight + (index > 0 ? GROUP_LABEL_DIVIDER : 0);

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

  /**
   * Keeps the keyboard's current option in view by scrolling the list only,
   * like upstream's `scrollToItem`: `scrollIntoView` would also scroll the
   * page, e.g. to a single-selection list's checked option on first render.
   */
  scrollActiveIntoView = modifier((list: HTMLElement, [index]: [number | undefined]) => {
    if (index === undefined || index < 0) return;

    const item = list.querySelectorAll<HTMLElement>(':scope > ul > li')[index];

    if (!item) return;

    const listBox = list.getBoundingClientRect();
    const itemBox = item.getBoundingClientRect();

    // rects are in screen pixels, scrollTop in the list's own (a transformed
    // ancestor scales them)
    const scale = list.offsetHeight ? listBox.height / list.offsetHeight : 1;

    if (itemBox.top < listBox.top) {
      list.scrollTop -= (listBox.top - itemBox.top) / scale;
    } else if (itemBox.bottom > listBox.bottom) {
      list.scrollTop += (itemBox.bottom - listBox.bottom) / scale;
    }
  });

  <template>
    <div class="euiSelectableList {{this.classes.root}}" ...attributes>
      <div
        class="euiSelectableList__list {{this.classes.list}}"
        tabindex="-1"
        style={{cssStyle (hash height=this.listHeight)}}
        data-skip-axe="scrollable-region-focusable"
        {{this.scrollActiveIntoView @activeOptionIndex}}
      >
        <ul
          id={{@listId}}
          class={{this.classes.ul}}
          role="listbox"
          tabindex={{unless @searchable "0"}}
          aria-multiselectable={{if this.isMultiSelectable "true"}}
          aria-label={{@ariaLabel}}
          aria-describedby={{@ariaDescribedby}}
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
                class="euiSelectableList__groupLabel {{this.classes.groupLabel}}"
                style={{cssStyle (hash height=(this.groupLabelHeight index))}}
              >{{option.prepend}}{{option.label}}{{option.append}}</li>
            {{else}}
              <EuiSelectableListItem
                id={{this.optionId index}}
                class={{option.className}}
                style={{cssStyle (hash height=this.rowHeight)}}
                aria-posinset={{this.posInSet index}}
                aria-setsize={{sub this.optionArray.length this.groupLabelCount}}
                @title={{titleOf option}}
                @isFocused={{this.isFocused index}}
                @checked={{option.checked}}
                @disabled={{option.disabled}}
                @hasPrepend={{or2 customPrepend option.prepend}}
                @hasAppend={{or2 customAppend option.append}}
                @showIcons={{@showIcons}}
                @onFocusBadge={{@onFocusBadge}}
                @allowExclusions={{@allowExclusions}}
                @singleSelection={{this.itemSingleSelection}}
                @searchable={{@searchable}}
                @isInteractive={{true}}
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

// an option's own `title` (e.g. the sitewide template's label + meta) wins
function titleOf(option: EuiSelectableOption): string {
  return typeof option['title'] === 'string'
    ? option['title']
    : (option.searchableLabel ?? option.label);
}

function sub(a: number, b: number): number {
  return a - b;
}
