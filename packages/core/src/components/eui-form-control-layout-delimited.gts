import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { and, or } from 'ember-truth-helpers';
import EuiFormControlLayout from '@ember-eui/core/components/eui-form-control-layout';
import EuiText from '@ember-eui/core/components/eui-text';

<template>
  {{#let
    (has-block "prepend")
    (has-block "append")
    (has-block "delimiter")
    (argOrDefault @delimiter "→")
    (argOrDefault @useGroup true)
    as |hasPrepend hasAppend hasDelimeterBlock delimiter useGroup|
  }}
    <EuiFormControlLayout
      class="euiFormControlLayoutDelimited"
      @icon={{@icon}}
      @clear={{@clear}}
      @fullWidth={{@fullWidth}}
      @isLoading={{@isLoading}}
      @compressed={{@compressed}}
      @readOnly={{@readOnly}}
      @disabled={{@disabled}}
      @useGroup={{and useGroup (or hasPrepend hasAppend)}}
    >
      <:prepend as |prependClasses|>
        {{yield prependClasses to="prepend"}}
      </:prepend>
      <:field>
        {{yield "euiFormControlLayoutDelimited__input" to="startControl"}}
        <EuiText
          class="euiFormControlLayoutDelimited__delimeter"
          @size="s"
          @color="subdued"
        >
          {{#if (or delimiter hasDelimeterBlock)}}
            {{#if hasDelimeterBlock}}
              {{yield to="delimiter"}}
            {{else}}
              {{delimiter}}
            {{/if}}
          {{/if}}
        </EuiText>
        {{yield "euiFormControlLayoutDelimited__input" to="endControl"}}
      </:field>
      <:append as |appendClasses|>
        {{yield appendClasses to="append"}}
      </:append>
    </EuiFormControlLayout>
  {{/let}}
</template>
