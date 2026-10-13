import Component from '@glimmer/component';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { modifier } from 'ember-modifier';
import { and, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { formControlReset } from '../utils/eui/form-controls.ts';
import { euiFieldNumberStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type { CommonArgs } from './common.ts';
import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';
import type { IconType } from './eui-icon';

/**
 * Upstream sets `aria-invalid` when the browser itself finds the number
 * invalid (out of `min`/`max`, off `step`, unparsable), re-checked whenever
 * the constraints change and on key up. Runs after `validatableControl`.
 */
const nativeValidity = modifier(function nativeValidity(
  element: HTMLInputElement,
  [isInvalid]: [boolean | undefined, ...unknown[]]
) {
  const check = () => {
    if (isInvalid || !element.validity.valid) {
      element.setAttribute('aria-invalid', 'true');
    } else {
      element.removeAttribute('aria-invalid');
    }
  };
  check();
  element.addEventListener('keyup', check);
  return () => element.removeEventListener('keyup', check);
});

export type EuiFieldNumberArgs = CommonArgs & {
  /** Id of the input, e.g. to match an `EuiFormRow`'s label. Defaults to a random id. */
  id?: string;
  /** Icon inside the input, anything `EuiIcon`'s `@type` accepts. */
  icon?: IconType;
  /**
   * Shows the invalid state (danger border and warning icon), sets
   * `aria-invalid` and marks the input invalid for native form validation.
   * A natively invalid value (e.g. above `@max`) also sets `aria-invalid`.
   */
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
   * Defaults to `'any'` (upstream), so decimals are not natively invalid.
   */
  step?: number | 'any';
  /** Called with the `<input>` element once rendered. */
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

  /** Shorter input (32px instead of 40px), for dense forms. */
  compressed?: boolean;

  /** @private Show the `<:prepend>` block. Defaults to `true`. */
  isPrependProvided?: boolean;
  /** @private Show the `<:append>` block. Defaults to `true`. */
  isAppendProvided?: boolean;

  /** Shows a clear ("x") button calling this function; empty the value there. */
  clear?: EuiFormControlLayoutSignature['Args']['clear'];
  /**
   * Extra styles composed last into the input's class (like upstream's
   * `css` prop). Prefer this to an extra class when styling it from a parent.
   */
  css?: EuiCss;
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

/** A number input on the upstream EUI 123 / Borealis form control styles. */
export default class EuiFieldNumber extends Component<EuiFieldNumberSignature> {
  nativeValidity = nativeValidity;

  get step() {
    return this.args.step ?? 'any';
  }

  inputClasses = (inGroup: boolean) => {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFieldNumberStyles);
    const { compressed, fullWidth, controlOnly } = this.args;
    return `euiFieldNumber ${euiClass(
      context,
      formControlReset,
      styles.euiFieldNumber,
      compressed ? styles.compressed : styles.uncompressed,
      fullWidth ? styles.fullWidth : styles.formWidth,
      !controlOnly && inGroup && styles.inGroup,
      controlOnly && styles.controlOnly,
      this.args.css
    )}`;
  };

  <template>
    {{#let
      (and (argOrDefault @isPrependProvided true) (has-block "prepend"))
      (and (argOrDefault @isAppendProvided true) (has-block "append"))
      (argOrDefault @id (randomId))
      as |hasPrepend hasAppend inputId|
    }}
      {{#let (this.inputClasses (or hasPrepend hasAppend)) as |classes|}}
        {{#if @controlOnly}}
          <input
            id={{@id}}
            class={{classes}}
            value={{@value}}
            min={{@min}}
            max={{@max}}
            disabled={{@disabled}}
            step={{this.step}}
            type="number"
            readonly={{@readOnly}}
            {{validatableControl @isInvalid}}
            {{this.nativeValidity @isInvalid @value @min @max this.step}}
            {{didInsert (optional @inputRef)}}
            ...attributes
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
                step={{this.step}}
                type="number"
                readonly={{@readOnly}}
                {{validatableControl @isInvalid}}
                {{this.nativeValidity @isInvalid @value @min @max this.step}}
                {{didInsert (optional @inputRef)}}
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
  </template>
}
