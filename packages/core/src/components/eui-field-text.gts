import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import validatableControl from '@ember-eui/core/modifiers/validatable-control';

import optional from 'ember-composable-helpers/helpers/optional';
import { and, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import uniqueId from '../helpers/unique-id';
import EuiFormControlLayout from './eui-form-control-layout';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  {{#let
    (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
    (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
    (argOrDefault @id (uniqueId))
    as |hasPrepend hasAppend inputId|
  }}
    {{#let
      (classNames
        (if @icon "euiFieldText--withIcon")
        (if @fullWidth "euiFieldText--fullWidth")
        (if @compressed "euiFieldText--compressed")
        (if (or hasPrepend hasAppend) "euiFieldText--inGroup")
        (if @isLoading "euiFieldText--isLoading")
        "euiFieldText"
      )
      as |classes|
    }}
      {{#if @controlOnly}}
        <input
          id={{inputId}}
          value={{@value}}
          class={{classes}}
          disabled={{@disabled}}
          type="text"
          placeholder={{@placeholder}}
          ...attributes
          {{validatableControl @isInvalid}}
          {{didInsert (optional @inputRef)}}
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
              ...attributes
              {{validatableControl @isInvalid}}
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
