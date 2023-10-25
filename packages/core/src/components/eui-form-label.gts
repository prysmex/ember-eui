import classNames from '@ember-eui/core/helpers/class-names';
import { eq } from 'ember-truth-helpers';

<template>
  {{#let
    (classNames
      (if @isFocused "euiFormLabel-isFocused")
      (if @isInvalid "euiFormLabel-isInvalid")
      "euiFormLabel"
    )
    as |classes|
  }}
    {{#if (eq @type "legend")}}
      <legend class={{classes}} for={{@for}} ...attributes>
        {{@label}}
        {{yield}}
      </legend>
    {{else}}
      <label class={{classes}} for={{@for}} ...attributes>
        {{@label}}
        {{yield}}
      </label>
    {{/if}}
  {{/let}}
</template>
