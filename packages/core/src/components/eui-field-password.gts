import classNames from '@ember-eui/core/helpers/class-names';
import { and, not, or, eq } from 'ember-truth-helpers';
import validatableControl from '@ember-eui/core/modifiers/validatable-control';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import EuiFormControlLayout from '@ember-eui/core/components/eui-form-control-layout';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import EuiButtonIcon from '@ember-eui/core/components/eui-button-icon';
import { optional } from 'ember-composable-helpers/components/optional';
import useState from '@ember-eui/core/helpers/use-state';

<template>
  {{#let
    (argOrDefault @type "dual")
    (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
    (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
    (argOrDefault @id (unique-id))
    as |type hasPrepend hasAppend inputId|
  }}
    {{#let
      (useState (if (eq type "dual") "password" type))
      as |inputTypeState|
    }}
      {{#let
        (classNames
          (if @fullWidth "euiFieldPassword--fullWidth")
          (if @compressed "euiFieldPassword--compressed")
          (if
            (or hasPrepend hasAppend (eq type "dual"))
            "euiFieldPassword--inGroup"
          )
          (if @isLoading "euiFieldPassword--isLoading")
          (if (eq type "dual") "euiFieldPassword--withToggle")
          "euiFieldPassword"
        )
        as |classes|
      }}
        {{#let (eq inputTypeState.value "text") as |isVisible|}}
          <EuiFormControlLayout
            @icon="lock"
            @clear={{@clear}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @compressed={{@compressed}}
            @readOnly={{@readOnly}}
            @disabled={{@disabled}}
            @useGroup={{or hasPrepend (or hasAppend (eq type "dual"))}}
          >
            <:prepend as |prependClasses|>
              {{yield prependClasses inputId to="prepend"}}
            </:prepend>
            <:field>
              <input
                id={{inputId}}
                class={{classes}}
                type={{inputTypeState.value}}
                value={{@value}}
                disabled={{@disabled}}
                ...attributes
                {{validatableControl @isInvalid}}
                {{didInsert (optional @inputRef)}}
              />
            </:field>
            <:append as |appendClasses|>
              {{yield appendClasses inputId to="append"}}
              {{#if (eq type "dual")}}
                <EuiButtonIcon
                  tabindex="-1"
                  @iconType={{if isVisible "eyeClosed" "eye"}}
                  {{on
                    "click"
                    (fn
                      inputTypeState.setState (if isVisible "password" "text")
                    )
                  }}
                />
              {{/if}}
            </:append>
          </EuiFormControlLayout>
        {{/let}}
      {{/let}}
    {{/let}}
  {{/let}}
</template>
