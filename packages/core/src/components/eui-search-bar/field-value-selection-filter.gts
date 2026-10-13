import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { waitForPromise } from '@ember/test-waiters';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiFilterGroupStyles } from '../../utils/eui/styles.generated.ts';
import { Operator } from '../../utils/eui/search-bar/ast.ts';
import { Query } from '../../utils/eui/search-bar/query.ts';
import EuiFilterButton from '../eui-filter-button.gts';
import EuiPopover from '../eui-popover.gts';
import EuiPopoverTitle from '../eui-popover-title.gts';
import EuiSelectable from '../eui-selectable.gts';
import EuiRenderNode from '../../-private/eui-render-node.gts';

import type Owner from '@ember/owner';
import type { ComponentLike } from '@glint/template';
import type {
  FieldValueOptionType,
  FieldValueSelectionFilterConfigType,
  MultiSelect
} from '../../-private/search-bar.ts';
import type { EuiSelectableOption } from '../../-private/selectable-options.ts';
import type EuiI18n from '../../services/eui-i18n';
import type { Clause, Value } from '../../utils/eui/search-bar/ast.ts';

/**
 * @private A filter button of `EuiSearchBar` opening a list of field values
 * (upstream `FieldValueSelectionFilter`): single or multi select, `and`
 * clauses or one `or` clause, sync or async (cached) options, a search above
 * `searchThreshold` options and checked options sorted first.
 */
export interface FieldValueSelectionFilterSignature {
  Args: {
    config: FieldValueSelectionFilterConfigType;
    query: Query;
    onChange: (query: Query) => void;
  };
}

const defaults = {
  config: {
    multiSelect: true,
    filterWith: 'prefix',
    searchThreshold: 10,
    autoSortOptions: true
  }
};

interface LoadedOptions {
  unsorted: FieldValueOptionType[];
  sorted: FieldValueOptionType[];
}

interface SelectionOption extends EuiSelectableOption {
  data: { view: string | ComponentLike; value: Value; optionField: string };
}

export default class FieldValueSelectionFilter extends Component<FieldValueSelectionFilterSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked popoverOpen = false;
  @tracked error: string | null = null;
  @tracked options: LoadedOptions | null;
  @tracked activeItemsCount = 0;
  cachedOptions: FieldValueOptionType[] | null = null;
  cacheTimeout: ReturnType<typeof setTimeout> | undefined;

  constructor(owner: Owner, args: FieldValueSelectionFilterSignature['Args']) {
    super(owner, args);
    const { options } = args.config;
    this.options = Array.isArray(options)
      ? { unsorted: options, sorted: options }
      : null;
    registerDestructor(this, () => clearTimeout(this.cacheTimeout));
  }

  get autoSortOptions(): boolean {
    return this.args.config.autoSortOptions ?? defaults.config.autoSortOptions;
  }

  get multiSelect(): MultiSelect {
    return this.args.config.multiSelect ?? defaults.config.multiSelect;
  }

  /** Upstream componentDidMount/componentDidUpdate: reload on query change. */
  watchQuery = modifier(
    (_element: Element, [query]: [Query]) => {
      if (query !== this.lastQuery) {
        const isFirst = this.lastQuery === undefined;
        this.lastQuery = query;
        if (!isFirst || query.text.length) void this.scheduleLoad();
      }
    }
  );

  lastQuery: Query | undefined;

  scheduleLoad(): Promise<void> {
    // after the render that consumed the state
    return waitForPromise(Promise.resolve().then(() => this.loadOptions()));
  }

  @action
  closePopover(): void {
    this.popoverOpen = false;
  }

  @action
  onButtonClick(): void {
    const wasOpen = this.popoverOpen;
    this.options = null;
    this.error = null;
    this.popoverOpen = !wasOpen;
    if (!wasOpen) {
      // loading options updates the state, so it runs in the animation frame
      void waitForPromise(
        new Promise<void>((resolve) =>
          window.requestAnimationFrame(() => {
            void this.loadOptions().then(resolve);
          })
        )
      );
    }
  }

  loadOptions = async (): Promise<void> => {
    if (this.isDestroying || this.isDestroyed) return;
    let loadedOptions: FieldValueOptionType[];
    this.options = null;
    this.error = null;

    const { options, cache } = this.args.config;
    try {
      if (Array.isArray(options)) {
        // Synchronous options, already loaded
        loadedOptions = options;
      } else {
        // Async options loader fn, potentially with a cache
        loadedOptions = this.cachedOptions ?? (await options());

        // If a cache time is set, populate the cache and schedule a cache reset
        if (cache != null && cache > 0) {
          this.cachedOptions = loadedOptions;
          this.cacheTimeout = setTimeout(() => {
            this.cachedOptions = null;
          }, cache);
        }
      }
    } catch {
      if (this.isDestroying || this.isDestroyed) return;
      this.options = null;
      this.error = 'Could not load options';
      return;
    }
    if (this.isDestroying || this.isDestroyed) return;

    const items: Record<'on' | 'off' | 'rest', FieldValueOptionType[]> = {
      on: [],
      off: [],
      rest: []
    };

    const { query, config } = this.args;

    if (loadedOptions) {
      loadedOptions.forEach((op) => {
        const optionField = op.field || config.field;
        if (optionField) {
          const clause =
            this.multiSelect === 'or'
              ? query.getOrFieldClause(optionField, op.value)
              : query.getSimpleFieldClause(optionField, op.value);
          const checked = this.resolveChecked(clause);
          if (!checked) {
            items.rest.push(op);
          } else if (checked === 'on') {
            items.on.push(op);
          } else {
            items.off.push(op);
          }
        }
      });
    }

    this.error = null;
    this.activeItemsCount = items.on.length;
    this.options = {
      unsorted: loadedOptions,
      sorted: [...items.on, ...items.off, ...items.rest]
    };
  };

  resolveOptionName(option: FieldValueOptionType): string {
    return option.name || String(option.value as string);
  }

  resolveChecked(clause: Clause | undefined): 'on' | 'off' | undefined {
    if (clause) {
      return Query.isMust(clause) ? 'on' : 'off';
    }
    return undefined;
  }

  isActiveField(field: string | undefined): boolean {
    if (typeof field !== 'string') {
      return false;
    }
    const { query } = this.args;
    if (this.multiSelect === 'or') {
      return query.hasOrFieldClause(field);
    }
    return query.hasSimpleFieldClause(field);
  }

  onOptionClick(field: string, value: Value, checked?: 'on' | 'off'): void {
    const { autoClose, operator = Operator.EQ } = this.args.config;

    // If the consumer explicitly sets `autoClose`, always defer to that.
    // Otherwise, default to auto-closing for single selections and leaving the
    // popover open for multi-select (so users can continue selecting options)
    const shouldClosePopover = autoClose ?? !this.multiSelect;
    if (shouldClosePopover) {
      this.closePopover();
    }

    const { query } = this.args;
    if (!this.multiSelect) {
      this.args.onChange(
        checked
          ? query
              .removeSimpleFieldClauses(field)
              .addSimpleFieldValue(field, value, true, operator)
          : query.removeSimpleFieldClauses(field)
      );
    } else if (this.multiSelect === 'or') {
      this.args.onChange(
        checked
          ? query.addOrFieldValue(field, value, true, operator)
          : query.removeOrFieldValue(field, value)
      );
    } else {
      this.args.onChange(
        checked
          ? query.addSimpleFieldValue(field, value, true, operator)
          : query.removeSimpleFieldValue(field, value)
      );
    }
  }

  get visibleOptions(): FieldValueOptionType[] | undefined {
    return this.autoSortOptions
      ? this.options?.sorted
      : this.options?.unsorted;
  }

  get active(): boolean {
    const { config } = this.args;
    const options = this.visibleOptions;
    const activeTop = this.isActiveField(config.field);
    const activeItem = options
      ? options.some((item) => this.isActiveField(item.field))
      : false;
    return (activeTop || activeItem) && this.activeItemsCount > 0;
  }

  get buttonLabel(): string {
    const hint = this.euiI18n.lookupToken(
      'euiFieldValueSelectionFilter.buttonLabelHint',
      'Selection'
    );
    return `${this.args.config.name} ${hint}`;
  }

  get items(): SelectionOption[] {
    const { query, config } = this.args;
    const options = this.visibleOptions;
    if (!options) return [];
    return options.map((option) => {
      const optionField = option.field || config.field;
      if (optionField == null) {
        throw new Error(
          'option.field or field should be provided in <FieldValueSelectionFilter/>'
        );
      }
      const clause =
        this.multiSelect === 'or'
          ? query.getOrFieldClause(optionField, option.value)
          : query.getSimpleFieldClause(optionField, option.value);
      const label = this.resolveOptionName(option);
      return {
        label,
        checked: this.resolveChecked(clause),
        data: { view: option.view ?? label, value: option.value, optionField }
      };
    });
  }

  get isOverSearchThreshold(): boolean {
    const threshold =
      this.args.config.searchThreshold || defaults.config.searchThreshold;
    const options = this.visibleOptions;
    return Boolean(options && options.length >= threshold);
  }

  @cached
  get panelCss() {
    const context = getEuiThemeContext(this);
    return useEuiBorealisStyles(context, euiFilterGroupStyles)
      .euiFilterGroup__popoverPanel;
  }

  @action
  onSelectableChange(options: EuiSelectableOption[]): void {
    // EuiSelectable reports every option; the clicked one is the option
    // that became checked (single selection also unchecks the previous one)
    const previous = this.items;
    const changes = options.filter(
      (option, i) => option.checked !== previous[i]?.checked
    );
    const changed = (changes.find((option) => option.checked) ??
      changes[0]) as SelectionOption | undefined;
    if (changed?.data) {
      this.onOptionClick(
        changed.data.optionField,
        changed.data.value,
        changed.checked === 'mixed' ? undefined : changed.checked
      );
    }
  }

  <template>
    <EuiPopover
      @isOpen={{this.popoverOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @anchorPosition="downCenter"
      @panelCss={{this.panelCss}}
      {{this.watchQuery @query}}
    >
      <:button>
        <EuiFilterButton
          @iconType="chevronSingleDown"
          @iconSide="right"
          @isSelected={{this.active}}
          @hasActiveFilters={{this.active}}
          @numActiveFilters={{if this.active this.activeItemsCount}}
          @grow={{true}}
          aria-label={{this.buttonLabel}}
          aria-expanded={{if this.popoverOpen "true" "false"}}
          {{on "click" this.onButtonClick}}
        >{{@config.name}}</EuiFilterButton>
      </:button>
      <:content>
        <EuiSelectable
          @singleSelection={{if this.multiSelect false true}}
          @options={{this.items}}
          @onChange={{this.onSelectableChange}}
          @isLoading={{isLoading this.options this.error}}
          @loadingMessage={{@config.loadingMessage}}
          @emptyMessage={{if this.error this.error @config.noOptionsMessage}}
          @noMatchesMessage={{@config.noOptionsMessage}}
          @listProps={{LIST_PROPS}}
          @searchable={{this.isOverSearchThreshold}}
          @searchProps={{SEARCH_PROPS}}
        >
          <:default as |parts|>
            {{#if parts.search}}
              <EuiPopoverTitle @paddingSize="s">
                <parts.search />
              </EuiPopoverTitle>
            {{/if}}
            <parts.list>
              <:option as |option|><EuiRenderNode @value={{viewOf option}} /></:option>
            </parts.list>
          </:default>
        </EuiSelectable>
      </:content>
    </EuiPopover>
  </template>
}

const LIST_PROPS = { paddingSize: 's' as const };
const SEARCH_PROPS = { compressed: true };

function isLoading(options: LoadedOptions | null, error: string | null): boolean {
  return options == null && error == null;
}

function viewOf(option: EuiSelectableOption): string | ComponentLike {
  return (option as SelectionOption).data?.view ?? option.label;
}
