import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { and, eq } from 'ember-truth-helpers';
import EuiFieldNumber from '@ember-eui/core/components/eui-field-number';
import { hash } from '@ember/helper';
import simpleStyle from '@ember-eui/core/modifiers/simple-style';
import inlineStyles from '@ember-eui/core/helpers/inline-styles';
import castTo from '@ember-eui/core/helpers/cast-to';

import { EuiFieldNumberArgs } from '@ember-eui/core/components/eui-field-number';

export interface EuiRangeInputArgs
  extends Omit<EuiFieldNumberArgs, 'max' | 'min' | 'value'> {
  autoSize?: boolean;
  digitTolerance: number;
  max: number;
  min: number;
  side?: 'min' | 'max';
  value: string | number;
}

<template>
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
      @value={{if (eq @value "") "" (castTo @value to="number")}}
      @disabled={{@disabled}}
      @compressed={{@compressed}}
      @fullWidth={{@fullWidth}}
      @controlOnly={{@controlOnly}}
      @isPrependProvided={{hasAppend}}
      @isAppendProvided={{hasPrepend}}
      @isInvalid={{@isInvalid}}
      @disable={{@disable}}
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
</template>
