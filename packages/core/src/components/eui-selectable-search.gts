import Component from '@glimmer/component';
import { action } from '@ember/object';

import { getMatchingOptions } from '../-private/selectable-options.ts';
import EuiFieldSearch from './eui-field-search.gts';

import type { EuiSelectableOption } from '../-private/selectable-options.ts';

/**
 * The search field of an `EuiSelectable`: filters the options as you type.
 * Usually rendered for you by `EuiSelectable` with `@searchable={{true}}`.
 */
export interface EuiSelectableSearchSignature {
  Element: HTMLInputElement;
  Args: {
    /** The options to filter. */
    options: EuiSelectableOption[];
    /** Called with the matching options and the search. */
    onChange: (matchingOptions: EuiSelectableOption[], searchValue: string) => void;
    /** Placeholder of the field. */
    placeholder?: string;
    /** Initial search. */
    defaultValue?: string;
    /** Every option matches (they were already filtered, e.g. by a server). */
    isPreFiltered?: boolean;
    /** `id` of the list, to link the field to it for screen readers. */
    listId?: string;
    /** Smaller field. */
    compressed?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
  };
}

export default class EuiSelectableSearch extends Component<EuiSelectableSearchSignature> {
  searchValue = this.initialValue;

  get initialValue(): string {
    return this.args.defaultValue ?? '';
  }

  @action
  onSearch(value: string): void {
    if (value === this.searchValue) return;

    this.searchValue = value;
    this.args.onChange(getMatchingOptions(this.args.options, value, this.args.isPreFiltered), value);
  }

  <template>
    <EuiFieldSearch
      class="euiSelectableSearch"
      @placeholder={{@placeholder}}
      @value={{this.initialValue}}
      @incremental={{true}}
      @fullWidth={{true}}
      @compressed={{@compressed}}
      @isLoading={{@isLoading}}
      @onSearch={{this.onSearch}}
      autocomplete="off"
      aria-haspopup="listbox"
      role={{if @listId "combobox"}}
      aria-autocomplete={{if @listId "list"}}
      aria-expanded={{if @listId "true"}}
      aria-controls={{@listId}}
      ...attributes
    />
  </template>
}
