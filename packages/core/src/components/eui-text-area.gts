import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import validatableControl from '../modifiers/validatable-control';

import optional from 'ember-composable-helpers/helpers/optional';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  {{#let
    (classNames
      (if @fullWidth "euiTextArea--fullWidth")
      (if @compressed "euiTextArea--compressed")
      componentName="EuiTextArea"
      resize=(argOrDefault @resize "vertical")
    )
    (if @rows @rows (if @compressed 3 6))
    (argOrDefault @id (unique-id))
    as |classes definedRows id|
  }}
    <textarea
      id={{id}}
      value={{@value}}
      class={{classes}}
      rows={{definedRows}}
      disabled={{@disabled}}
      ...attributes
      {{validatableControl @isInvalid}}
      {{didInsert (optional @inputRef)}}
    >
      {{yield}}
    </textarea>
  {{/let}}
</template>
