import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import validatableControl from '../modifiers/validatable-control';
import { Browser } from '../utils/browser';
import { keys } from '../utils/keys';

import { and, not, or } from 'ember-truth-helpers';

import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import uniqueId from '../helpers/unique-id';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import type { EuiFormControlLayoutSignature } from './eui-form-control-layout.gts';

let isSearchSupported = false;

/**
 * You can find more typing on the template
 */
type EuiFieldSearchArgs = {
  value?: string;
  defaultValue?: string;

  /**
   * When `true` the search will be executed (that is, the `onSearch` will be called) as the
   * user types.
   */
  incremental?: boolean;
  /**
   * Optional callback method called on open and close with a single `isOpen` parameter
   */
  onKeyUp?: (e: KeyboardEvent) => void;
  onSearch: (value: string) => void;

  isFakePrependBlock?: boolean;
  isFakeAppendBlock?: boolean;
  fullWidth?: boolean;
  compressed?: boolean;
  isLoading?: boolean;
  isClearable?: boolean;
  disabled?: boolean;
  readOnly?: boolean;
  placeholder?: string;
  id?: string;
  isInvalid?: boolean;
  isDisabled?: boolean;
};

export interface EuiFieldSearchSignature {
  Element: HTMLInputElement;
  Args: EuiFieldSearchArgs;
  Blocks: {
    prepend: [...EuiFormControlLayoutSignature['Blocks']['prepend'], string];
    field: [];
    append: [...EuiFormControlLayoutSignature['Blocks']['append'], string];
  };
}

export default class EuiFieldSearch extends Component<EuiFieldSearchSignature> {
  @tracked inputElement: HTMLInputElement | null = null;
  @tracked value: string | undefined =
    this.args.value ||
    (this.args.defaultValue ? `${this.args.defaultValue}` : '');

  @argOrDefaultDecorator(false) incremental = false;

  @action
  setValue(e: Event): void {
    const value = (e.target as HTMLInputElement).value;
    if (this.value !== value) {
      this.value = value;
    }
    this.args.onSearch?.(this.value);
  }

  @action
  onKeyUp(
    incremental: boolean,
    onSearch: (value: string) => void,
    e: KeyboardEvent
  ): void {
    this.value = (e.target as HTMLInputElement).value;
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

  @action
  didUpdateValue() {
    this.value = this.args.value;
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
    this.value = '';

    if (this.args.onSearch && this.incremental) {
      this.args.onSearch('');
    }
  }

  @action
  didInsertInput(inputRef: HTMLInputElement): void {
    this.inputElement = inputRef;
    isSearchSupported = Browser.isEventSupported('search', this.inputElement);
  }

  <template>
    {{#let
      (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
      (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
      (argOrDefault @id (uniqueId))
      as |hasPrepend hasAppend inputId|
    }}
      {{#let
        (classNames
          (if @fullWidth "euiFieldSearch--fullWidth")
          (if @compressed "euiFieldSearch--compressed")
          (if (or hasPrepend hasAppend) "euiFieldSearch--inGroup")
          (if @isLoading "euiFieldSearch--isLoading")
          (if
            (and (argOrDefault @isClearable true) @value)
            "euiFieldSearch--isClearable"
          )
          "euiFieldSearch"
        )
        as |classes|
      }}
        <EuiFormControlLayout
          @icon="search"
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @disabled={{@disabled}}
          @clear={{if
            (and
              @isClearable
              @value
              (not @readOnly)
              (and (not @isDisabled) (not @disabled))
            )
            this.onClear
          }}
          @compressed={{@compressed}}
          @useGroup={{or hasPrepend hasAppend}}
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
              type="text"
              placeholder={{@placeholder}}
              ...attributes
              {{on "keyup" (fn this.onKeyUp this.incremental @onSearch)}}
              {{on "search" this.setValue}}
              {{on "change" this.setValue}}
              {{didInsert this.didInsertInput}}
              {{didUpdate this.didUpdateValue @value}}
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
