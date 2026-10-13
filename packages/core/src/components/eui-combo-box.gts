import 'ember-basic-dropdown/styles';

import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { isArray } from '@ember/array';
import { action } from '@ember/object';
import { service } from '@ember/service';
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
  flattenOptionGroups,
  partialStringMatcher,
  selectedOptionForSearchValue,
  sortMatchesByStartsWith,
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
import type { EuiComboBoxSortMatchesBy } from '../utils/eui/combo-box.ts';
import type { EuiComboBoxNode } from './eui-combo-box/node.gts';
import type { EuiComboBoxTruncationProps } from './eui-combo-box/option-text.gts';
import type { EuiTooltipArgs } from './eui-tool-tip';

export type { EuiComboBoxNode, EuiComboBoxTruncationProps };

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
     * one-item array). `{ asPlainText: true }` shows the selection as plain
     * text instead of a pill. Defaults to multiple selection.
     */
    singleSelection?:
      | boolean
      | {
          asPlainText?: boolean;
        };
    /**
     * Lets the user add the typed text as a new option: shows an "add"
     * option when nothing matches (or always, with
     * `@alwaysShowCreateOption`). Called with the search text and all
     * options (groups flattened); return `false` to reject it. Add the
     * result to `@options` / `@selectedOptions` yourself. Text equal to a
     * selected option is not added again, and text equal to the only
     * matching option selects that option (upstream).
     */
    onCreateOption?: EuiComboBoxOnCreateOption;
    /** Shows the "add" option even when some options match. */
    alwaysShowCreateOption?: boolean;
    /**
     * The options: strings, or objects shown by the default block (e.g.
     * `{{option.label}}`). Groups are `{ groupName: 'Fruits', options: [...] }`.
     * A promise is supported (shows `@loadingMessage` while pending).
     */
    options: any[];
    /**
     * Custom search, e.g. to query a server: `(term, select) => results`
     * (or a promise). Without it the options are filtered locally, by
     * `@searchField` for objects.
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
    /** Shows a spinner in the input, e.g. while options load. */
    isLoading?: boolean;
    /** Disables the combo box. */
    isDisabled?: boolean;
    /** @deprecated Has no effect; use `@isDisabled`. */
    readOnly?: boolean;
    /** Component rendered instead of `@searchMessage`. */
    searchMessageComponent?: any;
    /** Smaller combo box, for dense forms. */
    compressed?: boolean;
    /** Called when the input gets focus. */
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
    /** Closes the options list after selecting one. */
    closeOnSelect?: boolean;
    /** Focuses the combo box and opens its options on render. */
    autoFocus?: boolean;
    /** Option highlighted when the list opens. */
    defaultHighlighted?: any;
    /** Makes the options list as wide as the input. */
    matchTriggerWidth?: boolean;
    /** `tabindex` of the combo box. */
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
    /** Message when no option matches. Defaults to "No results found". */
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
     * no match, anything else for a match.
     */
    matcher?: (option: any, searchText: string) => number;
    /** Matching used when typing while the list is closed. */
    typeAheadOptionMatcher?: (option: any, searchText: string) => number;
    /** Icon in the input, anything `EuiIcon`'s `@type` accepts. */
    triggerIcon?: any;
    /** Called when a selected option's pill is removed. */
    removeTag?: (option: any) => void;
    /** Called on every input with the text and the select API. */
    onInput?: (text: string, select: any, event: Event) => any;
    /** Called on keydown; return `false` to prevent the default behavior. */
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
    /** `role` of the input. */
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
 * z-index of the options list: above EUI's modals (8000), flyouts and their
 * overlay masks, as before (ember-basic-dropdown reads it from a variable).
 */
export const COMBO_BOX_LIST_Z_INDEX = 99999;

export default class EuiComboBoxComponent extends Component<EuiComboBoxSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked select: any = null;
  @tracked private _resolvedOptions?: any[];
  @tracked searchText = '';
  @tracked private _searchResult?: any[];

  private _filterResultsCache: {
    results: any[];
    options: any[];
    searchText: string;
  } = { results: [], options: [], searchText: this.searchText };

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
        '--ember-basic-dropdown-content-z-index': String(
          COMBO_BOX_LIST_Z_INDEX
        ),
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

  get dropdownClass(): string {
    return [
      'euiPanel euiPanel--plain euiPopover__panel',
      this.panelClass,
      this.args.dropdownClass
    ]
      .filter(Boolean)
      .join(' ');
  }

  /**
   * The search text, as typed (upstream `searchValue`). Kept apart from
   * `select`, which is replaced on every highlight change: options derived
   * from it would re-run ember-power-select's options modifier, which
   * resets the highlight, in a loop.
   */
  @tracked searchValue = '';

  /**
   * Options given to ember-power-select: `@options`, with the matches
   * starting with the search text first for `@sortMatchesBy="startsWith"`.
   */
  @cached
  get powerSelectOptions(): any {
    const options = this.options;
    const search = this.searchValue;

    if (
      this.args.sortMatchesBy !== 'startsWith' ||
      !search.trim() ||
      !Array.isArray(options)
    ) {
      return options;
    }

    return sortMatchesByStartsWith(
      options,
      search,
      this.args.searchField,
      Boolean(this.args.isCaseSensitive)
    );
  }

  /**
   * `@matcher`, else upstream's partial string matcher when matching is
   * case-sensitive (ember-power-select's default ignores case and accents).
   */
  @cached
  get matcher(): ((option: any, searchText: string) => number) | undefined {
    if (this.args.matcher) return this.args.matcher;
    if (!this.args.isCaseSensitive) return undefined;

    return partialStringMatcher(this.args.searchField, true);
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

  <template>
    {{! @glint-nocheck: not typesafe yet }}

    <PowerSelect
      @multiple={{true}}
      ...attributes
      @onChange={{this.onChange}}
      @onFocus={{@onFocus}}
      @onBlur={{this.onBlur}}
      @onOpen={{this.onOpen}}
      @onClose={{@onClose}}
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
      @closeOnSelect={{@closeOnSelect}}
      @defaultHighlighted={{@defaultHighlighted}}
      @searchField={{@searchField}}
      @searchEnabled={{argOrDefault @searchEnabled true}}
      @tabindex={{@tabindex}}
      @initiallyOpened={{and (not @isDisabled) @autoFocus (not @noSuggestions)}}
      @triggerComponent={{component
        EuiComboBoxTrigger
        fullWidth=@fullWidth
        compressed=@compressed
        isInvalid=@isInvalid
        singleSelection=@singleSelection
        onClose=@removeTag
        onCreateOption=(if @onCreateOption this.onCreateOption)
        isLoading=@isLoading
        autoFocus=(and (not @isDisabled) @autoFocus)
        icon=@triggerIcon
        prepend=@prepend
        append=@append
        noSuggestions=@noSuggestions
      }}
      @matcher={{this.matcher}}
      @initiallyOpen={{@initiallyOpen}}
      @typeAheadOptionMatcher={{@typeAheadOptionMatcher}}
      @buildSelection={{this.buildSelection}}
      @search={{@search}}
      @onInput={{this.onInput}}
      @onKeydown={{@onKeydown}}
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
      @ariaLabel={{@ariaLabel}}
      @ariaLabelledBy={{@ariaLabelledBy}}
      @required={{@required}}
      @triggerRole={{@triggerRole}}
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
            this.select.searchText
            this.alwaysShowCreateOption
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
        searchField=@searchField
      }}
      @extra={{@extra}}
      @groupComponent={{component EuiComboBoxGroup}}
      @triggerClass={{classNames
        "euiComboBox"
        this.rootClass
        (if @isDisabled "euiComboBox-isDisabled")
        (if @isInvalid "euiComboBox-isInvalid")
        (if this.select.isOpen "euiComboBox-isOpen")
      }}
      @noMatchesMessageComponent={{if
        (and @onCreateOption (not this.alwaysShowCreateOption))
        (component
          EuiComboBoxCreateOption
          customOptionText=@customOptionText
          onCreateOption=this.onCreateOption
          select=this.select
          alwaysShow=false
          delimiter=@delimiter
        )
        (component EuiComboBoxNoMatchesMessage)
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

  //This is to allow scrolling between virtualized groups
  @cached
  get opts() {
    // `@options` may still be a promise (ember-power-select shows loading)
    const results = Array.isArray(this.results) ? this.results : [];

    return results.reduce((acc, curr) => {
      if (emberPowerSelectIsGroup(curr)) {
        acc.push(curr, ...curr.options);
      } else {
        acc.push(curr);
      }

      return acc;
    }, []);
  }

  @cached
  get options(): any[] {
    if (this._resolvedOptions) return toPlainArray(this._resolvedOptions);

    if (this.args.options) {
      return toPlainArray(this.args.options);
    } else {
      return [];
    }
  }

  @cached
  get results(): any[] {
    if (this.searchText.length > 0) {
      if (this.args.search) {
        return toPlainArray(this._searchResult || this.options);
      } else {
        if (
          this._filterResultsCache.options === this.options &&
          this._filterResultsCache.searchText === this.searchText
        ) {
          // This is an optimization to avoid filtering several times, which may be a bit expensive
          // if there are many options, if neither the options nor the searchtext have changed
          return this._filterResultsCache.results;
        }

        //@ts-ignore
        const results = this._filter(this.options, this.searchText);
        //eslint-disable-next-line
        this._filterResultsCache = {
          results,
          options: this.options,
          searchText: this.searchText
        };

        return results;
      }
    } else {
      return this.options;
    }
  }

  @action
  scrollTo(option: any, select: { results: []; uniqueId: string }): void {
    const optionsList = document.querySelector(
      `[data-combo-box-list="${select.uniqueId}"]`
    ) as HTMLElement;

    if (!optionsList) {
      return;
    }

    const index = this.opts.indexOf(option);

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

    const searchText = (select as { searchText?: string })?.searchText ?? '';

    if (searchText !== this.searchValue) this.searchValue = searchText;
  }

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

    return onOpen?.(select, event);
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

    if (
      delimiter &&
      text.endsWith(delimiter) &&
      this.setCustomOptions(text, { keepOpen: true })
    ) {
      const input = event?.target as HTMLInputElement | null;

      if (input && 'value' in input) input.value = '';

      return '';
    }

    return corrected as string | void;
  }

  /**
   * Upstream `onContainerBlur`: leaving the combo box adds the typed text,
   * so it does not look like a text input. Only with `@noSuggestions` or
   * `@delimiter` (see the docs' Ember differences).
   */
  @action
  onBlur(select: Select, event: FocusEvent): void {
    (this.args.onBlur as ((...args: unknown[]) => void) | undefined)?.(
      select,
      event
    );

    const api = select as Select & { searchText?: string; uniqueId?: string };

    if (
      !(this.args.noSuggestions || this.args.delimiter) ||
      !this.args.onCreateOption ||
      !api?.searchText
    ) {
      return;
    }

    const next = event?.relatedTarget as Node | null;
    const list = api.uniqueId
      ? document.getElementById(`ember-basic-dropdown-content-${api.uniqueId}`)
      : null;

    if (next && list?.contains(next)) return;

    this.setCustomOptions(api.searchText, { keepOpen: true });
  }

  /** The "add" option, Enter without matches, and `@noSuggestions` Enter. */
  @action
  onCreateOption() {
    this.setCustomOptions(this.select?.searchText ?? '');
  }

  /**
   * Upstream `setCustomOptions`: the text, or each value separated by
   * `@delimiter` (trimmed, without duplicates), is added.
   */
  setCustomOptions(text: string, { keepOpen = false } = {}): boolean {
    const delimiter = this.args.delimiter;
    const values = delimiter
      ? [...new Set(text.split(delimiter).map((value) => value.trim()))]
      : [text];
    let seen = this.args.selectedOptions;
    let selection = [...(seen ?? [])];
    let cleared = false;

    values.forEach((value) => {
      if (!value.length) return;

      // the consumer may have updated `@selectedOptions` already
      if (this.args.selectedOptions !== seen) {
        seen = this.args.selectedOptions;
        selection = [...(seen ?? [])];
      }

      const result = this.addCustomOption(value, selection);

      if (result === false) return;

      cleared = true;

      if (result) selection = result;
    });

    if (cleared) {
      this.select?.actions.search('');
    }

    // like before: adding closes the list (upstream keeps it open for
    // multiple selection); typing a delimiter keeps typing going
    if (cleared && !keepOpen) {
      (this.select as any)?.actions.close();
    }

    return cleared;
  }

  /**
   * Upstream `addCustomOption` for one value: the only matching option
   * when its label equals the value, else `@onCreateOption` unless an
   * option with that label is selected. Returns the new selection when an
   * existing option was chosen, `false` when nothing was added.
   */
  addCustomOption(value: string, selection: any[]): any[] | false | void {
    const { isCaseSensitive, searchField, singleSelection } = this.args;
    const matched = this.onlyMatchingOption(value, selection);

    if (matched !== undefined) {
      const next = singleSelection ? [matched] : [...selection, matched];

      this.args.onChange(next);

      return next;
    }

    if (!this.args.onCreateOption) return false;

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
      flattenOptionGroups(Array.isArray(this.options) ? this.options : [])
    );

    // the consumer rejects a custom option explicitly
    if (created === false) return false;
  }

  /**
   * Upstream `doesSearchMatchOnlyOption`: the value matches exactly one
   * (enabled, unselected) option, and equals its label.
   */
  onlyMatchingOption(value: string, selection: any[]): unknown {
    const { isCaseSensitive, searchField } = this.args;
    const options = flattenOptionGroups(
      Array.isArray(this.options) ? this.options : []
    );
    const matcher =
      this.matcher ?? partialStringMatcher(searchField, Boolean(isCaseSensitive));
    const matches = options.filter(
      (option) =>
        !(option as { disabled?: boolean } | null)?.disabled &&
        !(this.args.singleSelection ? false : selection.includes(option)) &&
        matcher(option, value) >= 0
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

  @action
  buildSelection(option: any, select: Select) {
    const newSelection = (select.selected || []).slice(0);
    let idx = -1;

    for (let i = 0; i < newSelection.length; i++) {
      if (isEqual(newSelection[i], option)) {
        idx = i;

        break;
      }
    }

    if (idx > -1) {
      newSelection.splice(idx, 1);
    } else {
      newSelection.push(option);
    }

    if (this.args.singleSelection && newSelection.length === 0) {
      select.actions.search('');
    }

    if (select?.selected?.length < newSelection.length) {
      select.actions.search('');
    }

    return newSelection;
  }
}
