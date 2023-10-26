import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { eq } from 'ember-truth-helpers';

<template>
  {{#let (argOrDefault @display "visible") as |display|}}
    <legend
      class={{classNames
        (if (eq display "hiddden") "euiFormLengend--isHidden")
        (if @compressed "euiFormLegend--compresed")
        "euiFormLegend"
      }}
      ...attributes
    >
      {{#if (eq display "hidden")}}
        <span {{screen-reader-only}}>
          {{yield}}
        </span>
      {{else}}
        {{yield}}
      {{/if}}
    </legend>
  {{/let}}
</template>
