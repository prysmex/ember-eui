import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import { Browser } from '../utils/browser/index.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { formControlReset } from '../utils/eui/form-controls.ts';
import { euiFieldSearchStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { keys } from '../utils/keys.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';

let isSearchSupported = false;

/**
 * You can find more typing on the template
 */
type EuiFieldSearchArgs = {
  /** The search text. Update it in `@onSearch`. */
  value?: string;
  /** Initial text when `@value` is not passed. */
  defaultValue?: string;

  /**
   * When `true` the search will be executed (that is, the `onSearch` will be called) as the
   * user types.
   */
  incremental?: boolean;
  /**
   * Called on keyup, before `@onSearch`; call `event.preventDefault()` to
   * skip the search.
   */
  onKeyUp?: (e: KeyboardEvent) => void;
  /**
   * Called with the text when the user presses Enter or clears the field,
   * and on every keystroke with `@incremental`.
   */
  onSearch: (value: string) => void;

  /** @private Ignore the `<:prepend>` block. */
  isFakePrependBlock?: boolean;
  /** @private Ignore the `<:append>` block. */
  isFakeAppendBlock?: boolean;
  /** Stretches the input to its container's width. */
  fullWidth?: boolean;
  /** Shorter input (32px instead of 40px), for dense forms. */
  compressed?: boolean;
  /** Shows a spinner in the input. */
  isLoading?: boolean;
  /** Shows a clear button while the field has text. Defaults to `true`. */
  isClearable?: boolean;
  /** Disables the input. */
  disabled?: boolean;
  /** Makes the input read-only (and hides the clear button). */
  readOnly?: boolean;
  /** Placeholder text. */
  placeholder?: string;
  /** Id of the input, e.g. to match an `EuiFormRow`'s label. Defaults to a random id. */
  id?: string;
  /**
   * Shows the invalid state (danger border and warning icon), sets
   * `aria-invalid` and marks the input invalid for native form validation.
   */
  isInvalid?: boolean;
  /** Hides the clear button; use `@disabled` to disable the input. */
  isDisabled?: boolean;
};

export interface EuiFieldSearchSignature {
  Element: HTMLInputElement;
  Args: EuiFieldSearchArgs;
  Blocks: {
    /** Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. */
    prepend: [...EuiFormControlLayoutSignature['Blocks']['prepend'], string];
    field: [];
    /** Content after the input; yields the class to put on it and the input id. */
    append: [...EuiFormControlLayoutSignature['Blocks']['append'], string];
  };
}

/**
 * A `type="search"` input on the upstream EUI 123 / Borealis form control
 * styles, with a clear button and Enter/incremental search.
 */
export default class EuiFieldSearch extends Component<EuiFieldSearchSignature> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  /**
   * The value last passed to `@onSearch` by a `search` or `change` event,
   * reset on input: Enter in a `type="search"` input fires both events.
   */
  lastSearched: string | null = null;

  @tracked inputElement: HTMLInputElement | null = null;

  /**
   * The text the user typed (or the clear button emptied), valid while
   * `@value` is the one it was typed over. A changed `@value` wins, so the
   * field follows a controlled value without writing tracked state from a
   * modifier during the render (which broke the clear button's
   * `{{on "click" @clear}}` when the value became empty).
   */
  @tracked typed: string | undefined;
  typedOver: string | undefined = this.args.value;

  get value(): string {
    if (this.typed !== undefined && this.typedOver === this.args.value) {
      return this.typed;
    }

    return (
      this.args.value ||
      (this.args.defaultValue ? `${this.args.defaultValue}` : '')
    );
  }

  setTyped(value: string): void {
    this.typedOver = this.args.value;
    this.typed = value;
  }

  @argOrDefaultDecorator(false) incremental = false;

  @action
  setValue(e: Event): void {
    const value = (e.target as HTMLInputElement).value;

    if (this.value !== value) {
      this.setTyped(value);
    }

    if (this.lastSearched === value) return;
    this.lastSearched = value;
    this.args.onSearch?.(value);
  }

  @action
  onKeyUp(
    incremental: boolean,
    onSearch: (value: string) => void,
    e: KeyboardEvent
  ): void {
    this.setTyped((e.target as HTMLInputElement).value);

    if (this.args.onKeyUp) {
      this.args.onKeyUp(e);

      if (e.defaultPrevented) {
        return;
      }
    }

    if (
      onSearch &&
      ((e.key !== keys.ENTER && incremental) ||
        (e.key === keys.ENTER && !isSearchSupported))
    ) {
      onSearch((e.target as HTMLInputElement).value);
    }
  }

  /** Keeps the text current for the clear button (e.g. after a paste). */
  @action
  trackValue(e: Event): void {
    this.setTyped((e.target as HTMLInputElement).value);
    this.lastSearched = null;
  }

  @action
  onClear(): void {
    const nativeInputValue = Object.getOwnPropertyDescriptor(
      HTMLInputElement.prototype,
      'value'
    );
    const nativeInputValueSetter = nativeInputValue
      ? nativeInputValue.set
      : undefined;

    if (nativeInputValueSetter) {
      nativeInputValueSetter.call(this.inputElement, '');
    }

    // dispatch input event, with IE11 support/fallback
    let event;

    if ('Event' in window && typeof Event === 'function') {
      event = new Event('input', {
        bubbles: true,
        cancelable: false
      });
    } else {
      // IE11
      event = document.createEvent('Event');
      event.initEvent('input', true, false);
    }

    if (this.inputElement) {
      if (event) {
        this.inputElement.dispatchEvent(event);
      }

      // set focus on the search field
      this.inputElement.focus();
      this.inputElement.dispatchEvent(new Event('change'));
    }

    this.setTyped('');

    if (this.args.onSearch && this.incremental) {
      this.args.onSearch('');
    }
  }

  @action
  didInsertInput(inputRef: HTMLInputElement): void {
    this.inputElement = inputRef;
    isSearchSupported = Browser.isEventSupported('search', this.inputElement);
  }

  get clearLabel() {
    return this.euiI18n.lookupToken(
      'euiFieldSearch.clearSearchButtonLabel',
      'Clear search input'
    );
  }

  inputClasses = (inGroup: boolean) => {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFieldSearchStyles);
    const { compressed, fullWidth } = this.args;
    return `euiFieldSearch ${euiClass(
      context,
      formControlReset,
      styles.euiFieldSearch,
      compressed ? styles.compressed : styles.uncompressed,
      fullWidth ? styles.fullWidth : styles.formWidth,
      inGroup && styles.inGroup
    )}`;
  };

  willDestroy(): void {
    super.willDestroy();

    this.inputElement = null;
  }

  <template>
    {{#let
      (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
      (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
      (argOrDefault @id (randomId))
      as |hasPrepend hasAppend inputId|
    }}
      {{#let (this.inputClasses (or hasPrepend hasAppend)) as |classes|}}
        <EuiFormControlLayout
          @inputId={{inputId}}
          @icon="magnify"
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @isInvalid={{@isInvalid}}
          @disabled={{@disabled}}
          @clearLabel={{this.clearLabel}}
          @clear={{if
            (and
              (argOrDefault @isClearable true)
              this.value
              (not @readOnly)
              (and (not @isDisabled) (not @disabled))
            )
            this.onClear
          }}
          @compressed={{@compressed}}
          @readOnly={{@readOnly}}
          @isPrependProvided={{hasPrepend}}
          @isAppendProvided={{hasAppend}}
        >
          <:prepend as |prependClasses|>
            {{yield prependClasses inputId to="prepend"}}
          </:prepend>
          <:field>
            <input
              id={{inputId}}
              class={{classes}}
              value={{this.value}}
              disabled={{@disabled}}
              type="search"
              placeholder={{@placeholder}}
              readonly={{@readOnly}}
              aria-invalid={{if @isInvalid "true"}}
              ...attributes
              {{on "input" this.trackValue}}
              {{on "keyup" (fn this.onKeyUp this.incremental @onSearch)}}
              {{on "search" this.setValue}}
              {{on "change" this.setValue}}
              {{didInsert this.didInsertInput}}
              {{validatableControl @isInvalid}}
            />
          </:field>
          <:append as |appendClasses|>
            {{yield appendClasses inputId to="append"}}
          </:append>
        </EuiFormControlLayout>
      {{/let}}
    {{/let}}
  </template>
}
