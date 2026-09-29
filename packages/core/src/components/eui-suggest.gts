import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { action } from '@ember/object';

import EuiSuggestInput from './eui-suggest-input.gts';
import EuiSuggestItem from './eui-suggest-item.gts';

import type { EuiSuggestStatus } from './eui-suggest-input';
import type { EuiSuggestItemSignature } from './eui-suggest-item';

export interface EuiSuggestion {
  /** The suggestion's type: `{ iconType, color }` (`'tint0'`–`'tint10'`). */
  type: EuiSuggestItemSignature['Args']['type'];
  /** The suggestion. */
  label: string;
  /** More about it. */
  description?: string;
  /** Width of the label in percent. Defaults to `'50'`. */
  labelWidth?: EuiSuggestItemSignature['Args']['labelWidth'];
  /** `'truncate'` or `'wrap'` the description. */
  descriptionDisplay?: EuiSuggestItemSignature['Args']['descriptionDisplay'];
  [key: string]: unknown;
}

/**
 * A text field that suggests values as you type (fields, saved queries,
 * recent searches), with an optional save status. You filter the
 * suggestions from the typed text (`@onInputChange`) and handle the
 * chosen one (`@onItemClick`).
 */
export interface EuiSuggestSignature {
  Element: HTMLInputElement;
  Args: {
    /** The suggestions to show. */
    suggestions: EuiSuggestion[];
    /** Called with the clicked suggestion. */
    onItemClick?: (item: EuiSuggestion) => void;
    /** Called with the field's text on every change. */
    onInputChange?: (value: string) => void;
    /**
     * `'unsaved'`, `'saved'`, `'loading'` or `'unchanged'`. Defaults to
     * `'unchanged'`.
     */
    status?: EuiSuggestStatus;
    /** Tooltip of the status icon. */
    tooltipContent?: string;
    /** Placeholder of the field. */
    placeholder?: string;
  };
  Blocks: {
    /** Content after the field, e.g. a button. */
    append: [];
  };
}

export default class EuiSuggest extends Component<EuiSuggestSignature> {
  closePopover?: () => void;

  @action
  registerClose(close: () => void): void {
    this.closePopover = close;
  }

  @action
  onItemClick(item: EuiSuggestion): void {
    this.args.onItemClick?.(item);
    this.closePopover?.();
  }

  <template>
    <div>
      {{#if (has-block "append")}}
        <EuiSuggestInput
          @hasSuggestions={{if @suggestions.length true false}}
          @status={{@status}}
          @tooltipContent={{@tooltipContent}}
          @sendValue={{@onInputChange}}
          @placeholder={{@placeholder}}
          @registerClose={{this.registerClose}}
          ...attributes
        >
          <:default>
            {{#each @suggestions as |item|}}
              <EuiSuggestItem
                @type={{item.type}}
                @label={{item.label}}
                @description={{item.description}}
                @labelWidth={{item.labelWidth}}
                @descriptionDisplay={{item.descriptionDisplay}}
                @onClick={{if @onItemClick (fn this.onItemClick item)}}
              />
            {{/each}}
          </:default>
          <:append>{{yield to="append"}}</:append>
        </EuiSuggestInput>
      {{else}}
        <EuiSuggestInput
          @hasSuggestions={{if @suggestions.length true false}}
          @status={{@status}}
          @tooltipContent={{@tooltipContent}}
          @sendValue={{@onInputChange}}
          @placeholder={{@placeholder}}
          @registerClose={{this.registerClose}}
          ...attributes
        >
          {{#each @suggestions as |item|}}
            <EuiSuggestItem
              @type={{item.type}}
              @label={{item.label}}
              @description={{item.description}}
              @labelWidth={{item.labelWidth}}
              @descriptionDisplay={{item.descriptionDisplay}}
              @onClick={{if @onItemClick (fn this.onItemClick item)}}
            />
          {{/each}}
        </EuiSuggestInput>
      {{/if}}
    </div>
  </template>
}
