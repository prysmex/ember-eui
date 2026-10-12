import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { and } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { logicalStyle } from '../utils/eui/range.ts';
import { euiFormVariables } from '../utils/eui/styles.generated.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFieldNumber from './eui-field-number.gts';

import type { EuiFieldNumberArgs, EuiFieldNumberSignature } from './eui-field-number';

export interface EuiRangeInputArgs
  extends Omit<EuiFieldNumberArgs, 'max' | 'min' | 'value'> {
  /**
   * Sizes the input to its value (up to the longer of `@min`/`@max` plus one
   * character), as upstream. Defaults to `true`.
   */
  autoSize?: boolean;
  /** @deprecated Has no effect: the auto size follows the value, as upstream. */
  digitTolerance?: number;
  /** `name` of the input. */
  name?: string;
  /** Highest value. */
  max: number;
  /** Lowest value. */
  min: number;
  /** Which end it is for: `'min'` or `'max'`. */
  side?: 'min' | 'max';
  /** The value. */
  value?: string | number;
  /** Show the `<:prepend>` block. */
  isPrependProvided?: boolean;
  /** Show the `<:append>` block. */
  isAppendProvided?: boolean;
}

/** @private The number input of EuiRange / EuiDualRange (`@showInput`). */
export interface EuiRangeInputSignature {
  Element: EuiFieldNumberSignature['Element'];
  Args: EuiRangeInputArgs;
  Blocks: {
    prepend: [string];
    append: [string];
  };
}

/**
 * Upstream `EuiRangeInput`: an EuiFieldNumber sized to its value. Upstream's
 * `euiRangeInput` styles (`min-inline-size`, and the auto width) are applied
 * inline, because EuiFieldNumber has no `@css` yet.
 */
export default class EuiRangeInput extends Component<EuiRangeInputSignature> {
  get numberValue(): number | string | undefined {
    const { value } = this.args;
    return value === '' ? '' : value === undefined ? undefined : Number(value);
  }

  @cached
  get style() {
    const context = getEuiThemeContext(this);
    const { euiTheme } = context.upstream;
    const { min, max, value, compressed, isInvalid } = this.args;
    const autoSize = this.args.autoSize ?? true;
    let width: string | undefined;
    if (autoSize) {
      // Characters to show: the min/max length is the max, plus a UX buffer of 1
      const maxChars = Math.max(String(min).length, String(max).length) + 1;
      const inputCharWidth = Math.min(String(value).length, maxChars);
      const form = useEuiBorealisStyles(context, euiFormVariables);
      const padding = compressed ? form.controlCompressedPadding : form.controlPadding;
      const invalidIconWidth = isInvalid
        ? euiTheme.base * (compressed ? 1.125 : 1.375)
        : 0;
      // Guesstimated stepper width (a little wider in Firefox than in Chrome)
      width = `calc(${padding} + ${inputCharWidth}ch + 2em + ${invalidIconWidth}px)`;
    }
    return logicalStyle({ minWidth: `${euiTheme.base * 3.5}px`, width });
  }

  <template>
    {{#let
      (and (argOrDefault @isPrependProvided true) (has-block "prepend"))
      (and (argOrDefault @isAppendProvided true) (has-block "append"))
      as |hasPrepend hasAppend|
    }}
      <EuiFieldNumber
        class="euiRangeInput euiRangeInput--{{argOrDefault @side 'max'}}"
        style={{this.style}}
        name={{@name}}
        @min={{@min}}
        @max={{@max}}
        @step={{@step}}
        @value={{this.numberValue}}
        @disabled={{@disabled}}
        @readOnly={{@readOnly}}
        @compressed={{@compressed}}
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @controlOnly={{@controlOnly}}
        @isPrependProvided={{hasPrepend}}
        @isAppendProvided={{hasAppend}}
        @isInvalid={{@isInvalid}}
        ...attributes
      >
        <:prepend as |classes|>
          {{yield classes to="prepend"}}
        </:prepend>
        <:append as |classes|>
          {{yield classes to="append"}}
        </:append>
      </EuiFieldNumber>
    {{/let}}
  </template>
}
