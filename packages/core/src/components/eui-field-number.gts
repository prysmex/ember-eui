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
  id?: string;
  icon?: IconType;
  isInvalid?: boolean;
  fullWidth?: boolean;
  isLoading?: boolean;
  readOnly?: boolean;
  min?: number | string;
  max?: number | string;
  value?: number | string;
  disabled?: boolean;

  /**
   * Specifies the granularity that the value must adhere to.
   * Accepts a `number` or the string `'any'` for no stepping to allow for any value.
   * Defaults to `1`
   */
  step?: number | 'any';
  inputRef?: (ele: Element) => void;

  /**
   * Creates an input group with element(s) coming before input.
   * `string` | `Component` or an array of these
   */
  prepend?: EuiFormControlLayoutSignature['Blocks']['prepend'];

  /**
   * Creates an input group with element(s) coming after input.
   * `string` | `Component` or an array of these
   */
  append?: EuiFormControlLayoutSignature['Blocks']['append'];

  /**
   * Completely removes form control layout wrapper and ignores
   * icon, prepend, and append. Best used inside EuiFormControlLayoutDelimited.
   */
  controlOnly?: boolean;

  /**
   * when `true` creates a shorter height input
   */
  compressed?: boolean;

  isPrependProvided?: boolean;
  isAppendProvided?: boolean;

  clear?: EuiFormControlLayoutSignature['Args']['clear'];
};

export interface EuiFieldNumberSignature {
  Element: HTMLInputElement;
  Args: EuiFieldNumberArgs;
  Blocks: {
    default: [string];
    prepend: [string];
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
