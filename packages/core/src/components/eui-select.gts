import classNames from '@ember-eui/core/helpers/class-names';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { and, eq, or, not } from 'ember-truth-helpers';
import EuiFormControlLayout from '@ember-eui/core/components/eui-form-control-layout';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { optional } from 'ember-composable-helpers/helpers/optional';
import validatableControl from '@ember-eui/core/modifiers/validatable-control';

<template>
  {{#let
    (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
    (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
    (argOrDefault @id (unique-id))
    as |hasPrepend hasAppend inputId|
  }}
    {{#let
      (classNames
        (if @fullWidth "euiSelect--fullWidth")
        (if @compressed "euiSelect--compressed")
        (if (or hasPrepend hasAppend) "euiSelect--inGroup")
        (if @isLoading "euiSelect--isLoading")
        "euiSelect"
      )
      (argOrDefault @hasNoInitialSelection false)
      as |classes hasNoInitialSelection value|
    }}

      <EuiFormControlLayout
        @clear={{@clear}}
        @icon="arrowDown"
        @iconSide="right"
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @compressed={{@compressed}}
        @disabled={{@disabled}}
        @useGroup={{or hasPrepend hasAppend}}
      >
        <:prepend as |prependClasses|>
          {{yield prependClasses inputId to="prepend"}}
        </:prepend>
        <:field>
          <select
            id={{inputId}}
            class={{classes}}
            disabled={{@disabled}}
            ...attributes
            {{validatableControl @isInvalid}}
            {{didInsert (optional @inputRef)}}
          >
            {{#if hasNoInitialSelection}}
              {{! template-lint-disable}}
              <option
                value=""
                disabled
                hidden
                style="display: none"
                selected={{not @value}}
              ></option>
              {{! template-lint-enable}}
            {{/if}}
            {{#each @options as |opt|}}
              <option
                value={{opt.value}}
                selected={{eq @value opt.value}}
                disabled={{eq opt.disabled true}}
              >
                {{opt.text}}
              </option>
            {{/each}}
          </select>
        </:field>
        <:append as |appendClasses|>
          {{yield appendClasses inputId to="append"}}
        </:append>
      </EuiFormControlLayout>
    {{/let}}
  {{/let}}
</template>
