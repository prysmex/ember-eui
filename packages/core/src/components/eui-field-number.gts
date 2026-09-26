import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type { CommonArgs } from './common.ts';
import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';
import type { IconType } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export type EuiFieldNumberArgs = CommonArgs & {
  /** Id of the input, e.g. to match an `EuiFormRow`'s label. Defaults to a random id. */
  id?: string;
  /** Icon inside the input, anything `EuiIcon`'s `@type` accepts. */
  icon?: IconType;
  /** Shows the invalid state and marks the input invalid for native form validation. */
  isInvalid?: boolean;
  /** Stretches the input to its container's width. */
  fullWidth?: boolean;
  /** Shows a spinner in the input. */
  isLoading?: boolean;
  /** Makes the input read-only. */
  readOnly?: boolean;
  /** Lowest allowed value. */
  min?: number | string;
  /** Highest allowed value. */
  max?: number | string;
  /** The value. Update it from `{{on "input" …}}` (the event's value is a string). */
  value?: number | string;
  /** Disables the input. */
  disabled?: boolean;

  /**
   * Specifies the granularity that the value must adhere to.
   * Accepts a `number` or the string `'any'` for no stepping to allow for any value.
   * Defaults to `1`
   */
  step?: number | 'any';
  /** Called with the `<input>` element once rendered (only with `@controlOnly`). */
  inputRef?: (ele: Element) => void;

  /** @deprecated Has no effect, use the `<:prepend>` block. */
  prepend?: EuiFormControlLayoutSignature['Blocks']['prepend'];

  /** @deprecated Has no effect, use the `<:append>` block. */
  append?: EuiFormControlLayoutSignature['Blocks']['append'];

  /**
   * Completely removes form control layout wrapper and ignores
   * icon, prepend, and append. Best used inside EuiFormControlLayoutDelimited.
   */
  controlOnly?: boolean;

  /** Shorter input, for dense forms. */
  compressed?: boolean;

  /** @private Show the `<:prepend>` block. Defaults to `true`. */
  isPrependProvided?: boolean;
  /** @private Show the `<:append>` block. Defaults to `true`. */
  isAppendProvided?: boolean;

  /** Shows a clear ("x") button calling this function; empty the value there. */
  clear?: EuiFormControlLayoutSignature['Args']['clear'];
};

export interface EuiFieldNumberSignature {
  Element: HTMLInputElement;
  Args: EuiFieldNumberArgs;
  Blocks: {
    /** Unused. */
    default: [string];
    /** Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it. */
    prepend: [string];
    /** Content after the input, e.g. a unit; yields the class to put on it. */
    append: [string];
  };
}

const EuiFieldNumber: TemplateOnlyComponent<EuiFieldNumberSignature> =
  <template>
    {{#let
      (and (argOrDefault @isPrependProvided true) (has-block "prepend"))
      (and (argOrDefault @isAppendProvided true) (has-block "append"))
      (argOrDefault @id (randomId))
      as |hasPrepend hasAppend inputId|
    }}
      {{#let
        (classNames
          (if @icon "euiFieldNumber--withIcon")
          (if @fullWidth "euiFieldNumber--fullWidth")
          (if @compressed "euiFieldNumber--compressed")
          (if (or hasPrepend hasAppend) "euiFieldNumber--inGroup")
          (if @isLoading "euiFieldNumber--isLoading")
          "euiFieldNumber"
        )
        as |classes|
      }}
        {{#if @controlOnly}}
          <input
            id={{@id}}
            class={{classes}}
            value={{@value}}
            min={{@min}}
            max={{@max}}
            disabled={{@disabled}}
            step={{@step}}
            type="number"
            readonly={{@readOnly}}
            {{validatableControl @isInvalid}}
            {{didInsert (optional @inputRef)}}
            ...attributes
          />
        {{else}}
          <EuiFormControlLayout
            @icon={{@icon}}
            @clear={{@clear}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @compressed={{@compressed}}
            @readOnly={{@readOnly}}
            @disabled={{@disabled}}
            @useGroup={{or hasPrepend hasAppend}}
          >
            <:prepend as |prependClasses|>
              {{yield prependClasses to="prepend"}}
            </:prepend>
            <:field>
              <input
                id={{inputId}}
                class={{classes}}
                value={{@value}}
                min={{@min}}
                max={{@max}}
                disabled={{@disabled}}
                step={{@step}}
                type="number"
                readonly={{@readOnly}}
                {{validatableControl @isInvalid}}
                ...attributes
              />
            </:field>
            <:append as |appendClasses|>
              {{yield appendClasses to="append"}}
            </:append>
          </EuiFormControlLayout>
        {{/if}}
      {{/let}}
    {{/let}}
  </template>;

export default EuiFieldNumber;
