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
import EuiComboBoxCreateOption from './eui-combo-box/create-option.gts';
import EuiComboBoxGroup from './eui-combo-box/group.gts';
import EuiComboBoxNoMatchesMessage from './eui-combo-box/no-matches-message.gts';
import EuiComboBoxOptions from './eui-combo-box/options.gts';
import EuiComboBoxSearchMessage from './eui-combo-box/search-message.gts';
import EuiComboBoxTrigger from './eui-combo-box/trigger.gts';

import type EuiI18n from '../services/eui-i18n';

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
     * `@alwaysShowCreateOption`). Called with the search text; return
     * `false` to reject it, or a value to use instead of the text. Add the
     * result to `@options` / `@selectedOptions` yourself.
     */
    onCreateOption?: (search: string) => boolean | undefined;
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
    /** Height in px of each option in the (virtualized) list. */
    rowHeight?: number;
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
     * Renders each option, with its index: `as |option|` →
     * `{{option.label}}`. Strings can be rendered as they are.
     */
    default: [any, number, Select];
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

  <template>
    {{! @glint-nocheck: not typesafe yet }}

    <PowerSelect
      @multiple={{true}}
      ...attributes
      @onChange={{this.onChange}}
      @onFocus={{@onFocus}}
      @onBlur={{@onBlur}}
      @onOpen={{@onOpen}}
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
      @options={{this.options}}
      @selected={{@selectedOptions}}
      @closeOnSelect={{@closeOnSelect}}
      @defaultHighlighted={{@defaultHighlighted}}
      @searchField={{@searchField}}
      @searchEnabled={{argOrDefault @searchEnabled true}}
      @tabindex={{@tabindex}}
      @initiallyOpened={{and (not @isDisabled) @autoFocus}}
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
      }}
      @matcher={{@matcher}}
      @initiallyOpen={{@initiallyOpen}}
      @typeAheadOptionMatcher={{@typeAheadOptionMatcher}}
      @buildSelection={{this.buildSelection}}
      @search={{@search}}
      @onInput={{@onInput}}
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
          )
        )
      }}
      @placeholder={{@placeholder}}
      @searchPlaceholder={{@searchPlaceholder}}
      @optionsComponent={{component
        EuiComboBoxOptions
        rowHeight=@rowHeight
        class=@optionsClass
      }}
      @extra={{@extra}}
      @groupComponent={{component EuiComboBoxGroup}}
      @triggerClass={{classNames
        "euiComboBox"
        (if @compressed "euiComboBox--compressed")
        (if @fullWidth "euiComboBox--fullWidth")
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
        )
        (component EuiComboBoxNoMatchesMessage)
      }}
      @dropdownClass="euiComboBoxOptionsList euiPanel euiPanel--borderRadiusMedium euiPanel--noShadow euiPanel--plain euiPopover__panel-isAttached euiPopover__panel euiPopover__panel-noArrow euiPopover__panel--bottom euiPopover__panel-isOpen {{@dropdownClass}}"
      as |option i|
    >
      {{yield option i}}
    </PowerSelect>
  </template>

  //This is to allow scrolling between virtualized groups
  @cached
  get opts() {
    return this.results.reduce((acc, curr) => {
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
      `[aria-controls="ember-power-select-trigger-${select.uniqueId}"]`
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
  onCreateOption() {
    let option;

    if (
      this.args.onCreateOption &&
      typeof this.args.onCreateOption === 'function'
    ) {
      // The `onCreateOption` function can be used to sanitize the input or explicitly return `false` to reject the input
      option = this.args.onCreateOption(this.select.searchText);

      if (option === false) {
        return;
      }
    }

    const search = option || this.select.searchText;

    this.select.actions.search('');
    this.select.actions.close();

    return search;
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
