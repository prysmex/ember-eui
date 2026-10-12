import Component from '@glimmer/component';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { formControlReset } from '../utils/eui/form-controls.ts';
import { euiFieldTextStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';

export interface EuiFieldTextSignature {
  Element: HTMLInputElement;
  Args: {
    /** Id of the input, e.g. to match an `EuiFormRow`'s label. Defaults to a random id. */
    id?: string;
    /** The value. Update it from `{{on "input" …}}` on the component. */
    value?: string;
    /** Placeholder text. */
    placeholder?: string;
    /** Icon inside the input (left side), anything `EuiIcon`'s `@type` accepts. */
    icon?: EuiFormControlLayoutSignature['Args']['icon'];
    /** Stretches the input to its container's width. */
    fullWidth?: boolean;
    /** Shows a spinner in the input. */
    isLoading?: boolean;
    /** Shorter input (32px instead of 40px), for dense forms. */
    compressed?: boolean;
    /** Makes the input read-only. */
    readOnly?: boolean;
    /** Disables the input. */
    disabled?: boolean;
    /** Shows a clear ("x") button calling this function; empty the value there. */
    clear?: () => void;
    /**
     * Renders just the `<input>`, without the layout (icon, clear button,
     * prepend/append). Best used inside EuiFormControlLayoutDelimited.
     */
    controlOnly?: boolean;
    /**
     * Shows the invalid state (danger border and warning icon), sets
     * `aria-invalid` and marks the input invalid for native form validation.
     */
    isInvalid?: boolean;
    /** Called with the `<input>` element once rendered. */
    inputRef?: (element: HTMLInputElement | null) => void;
    /** @private Ignore the `<:prepend>` block. */
    isFakePrependBlock?: boolean;
    /** @private Ignore the `<:append>` block. */
    isFakeAppendBlock?: boolean;
  };
  Blocks: {
    /** Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. */
    prepend: [...EuiFormControlLayoutSignature['Blocks']['prepend'], string];
    /** Content after the input; yields the class to put on it and the input id. */
    append: [...EuiFormControlLayoutSignature['Blocks']['append'], string];
  };
}

/** A text input on the upstream EUI 123 / Borealis form control styles. */
export default class EuiFieldText extends Component<EuiFieldTextSignature> {
  inputClasses = (inGroup: boolean) => {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFieldTextStyles);
    const { compressed, fullWidth, controlOnly } = this.args;
    return `euiFieldText ${euiClass(
      context,
      formControlReset,
      styles.euiFieldText,
      compressed ? styles.compressed : styles.uncompressed,
      fullWidth ? styles.fullWidth : styles.formWidth,
      !controlOnly && inGroup && styles.inGroup,
      controlOnly && styles.controlOnly
    )}`;
  };

  <template>
    {{#let
      (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
      (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
      (argOrDefault @id (randomId))
      as |hasPrepend hasAppend inputId|
    }}
      {{#let (this.inputClasses (or hasPrepend hasAppend)) as |classes|}}
        {{#if @controlOnly}}
          <input
            id={{inputId}}
            value={{@value}}
            class={{classes}}
            disabled={{@disabled}}
            type="text"
            placeholder={{@placeholder}}
            readonly={{@readOnly}}
            aria-invalid={{if @isInvalid "true"}}
            ...attributes
            {{validatableControl @isInvalid}}
            {{didInsert (optional @inputRef)}}
          />
        {{else}}
          <EuiFormControlLayout
            @inputId={{inputId}}
            @icon={{@icon}}
            @clear={{@clear}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @isInvalid={{@isInvalid}}
            @compressed={{@compressed}}
            @readOnly={{@readOnly}}
            @disabled={{@disabled}}
            @isPrependProvided={{hasPrepend}}
            @isAppendProvided={{hasAppend}}
          >
            <:prepend as |prependClasses|>
              {{yield prependClasses inputId to="prepend"}}
            </:prepend>
            <:field>
              <input
                id={{inputId}}
                value={{@value}}
                class={{classes}}
                disabled={{@disabled}}
                type="text"
                placeholder={{@placeholder}}
                readonly={{@readOnly}}
                aria-invalid={{if @isInvalid "true"}}
                ...attributes
                {{validatableControl @isInvalid}}
                {{didInsert (optional @inputRef)}}
              />
            </:field>
            <:append as |appendClasses|>
              {{yield appendClasses inputId to="append"}}
            </:append>
          </EuiFormControlLayout>
        {{/if}}
      {{/let}}
    {{/let}}
  </template>
}
