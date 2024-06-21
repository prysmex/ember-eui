import { hash } from '@ember/helper';

import { and, eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import castTo from '../helpers/cast-to.ts';
import inlineStyles from '../helpers/inline-styles.ts';
import simpleStyle from '../modifiers/simple-style.ts';
import EuiFieldNumber from './eui-field-number.gts';

import type { EuiFieldNumberSignature } from './eui-field-number';
import type { EuiFieldNumberArgs } from './eui-field-number';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiRangeInputArgs
  extends Omit<EuiFieldNumberArgs, 'max' | 'min' | 'value'> {
  autoSize?: boolean;
  digitTolerance: number;
  name?: string;
  max: number;
  min: number;
  side?: 'min' | 'max';
  value?: string | number;
  isPrependProvided?: boolean;
  isAppendProvided?: boolean;
}

export interface EuiRangeInputSignature {
  Element: EuiFieldNumberSignature['Element'];
  Args: EuiRangeInputArgs;
  Blocks: {
    prepend: [string];
    append: [string];
  };
}

const EuiRangeInput: TemplateOnlyComponent<EuiRangeInputSignature> = <template>
  {{#let
    (and (argOrDefault @isPrependProvided true) (has-block "prepend"))
    (and (argOrDefault @isAppendProvided true) (has-block "append"))
    as |hasAppend hasPrepend|
  }}
    <EuiFieldNumber
      class="euiRangeInput euiRangeInput--{{argOrDefault @side 'max'}}"
      name={{@name}}
      min={{castTo @min to="number"}}
      max={{castTo @max to="number"}}
      @step={{@step}}
      {{!@glint-expect-error}}
      @value={{if (eq @value "") "" (castTo @value to="number")}}
      @disabled={{@disabled}}
      @compressed={{@compressed}}
      @fullWidth={{@fullWidth}}
      @controlOnly={{@controlOnly}}
      @isPrependProvided={{hasAppend}}
      @isAppendProvided={{hasPrepend}}
      @isInvalid={{@isInvalid}}
      ...attributes
      {{simpleStyle
        (inlineStyles
          componentName="EuiRangeInput"
          componentArgs=(hash
            autoSize=(argOrDefault @autoSize true)
            digitTolerance=@digitTolerance
          )
        )
      }}
    >
      <:prepend as |classes|>
        {{yield classes to="prepend"}}
      </:prepend>
      <:append as |classes|>
        {{yield classes to="append"}}
      </:append>
    </EuiFieldNumber>
  {{/let}}
</template>;

export default EuiRangeInput;
