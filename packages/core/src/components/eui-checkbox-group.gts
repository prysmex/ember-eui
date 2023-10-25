import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { concat } from '@ember/helper';
import { or } from 'ember-truth-helpers';
import EuiFormFieldset from '@ember-eui/core/components/eui-form-fieldset';
import EuiCheckbox from '@ember-eui/core/components/eui-checkbox';
import { on } from '@ember/modifier';
import validatableControl from '@ember-eui/core/modifiers/validatable-control';
import { get } from '@ember/helper';
import { fn } from '@ember/helper';

<template>
  {{#let
    (argOrDefault @valueKey "id") (argOrDefault @labelKey "label")
    as |valueKey labelKey|
  }}
    {{!template-lint-disable}}
    <input
      tabindex="-1"
      style="opacity: 0px; width:0px; height:0px; position: absolute; top: 40%; border:solid 1px transparent !important; margin:0px !important;"
      class="fake-input-for-html-form-validity"
      {{validatableControl @isInvalid}}
    />
    {{!template-lint-enable}}
    {{#if @legend}}
      <EuiFormFieldset @legend={{@legend}} @compressed={{@compressed}}>
        {{#each @options key=valueKey as |option|}}
          <EuiCheckbox
            form={{@formId}}
            class={{concat "euiCheckboxGroup__item" option.className}}
            @checked={{get @idToSelectedMap (get option valueKey)}}
            @disabled={{or @disabled option.disabled}}
            @compressed={{@compressed}}
            @label={{get option labelKey}}
            {{on "change" (fn @onChange (get option valueKey))}}
          />
        {{/each}}
      </EuiFormFieldset>
    {{else}}
      <div ...attributes>
        {{#each @options key=valueKey as |option|}}
          <EuiCheckbox
            form={{@formId}}
            class={{concat "euiCheckboxGroup__item" option.className}}
            @checked={{get @idToSelectedMap (get option valueKey)}}
            @disabled={{or @disabled option.disabled}}
            @compressed={{@compressed}}
            @label={{get option labelKey}}
            {{on "change" (fn @onChange (get option valueKey))}}
          />
        {{/each}}
      </div>
    {{/if}}
  {{/let}}
</template>
