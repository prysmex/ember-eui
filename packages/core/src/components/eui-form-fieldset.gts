import { or } from 'ember-truth-helpers';
import EuiFormLegend from './eui-form-legend';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <fieldset ...attributes>
    {{#if (or @legend (has-block "legend"))}}
      <EuiFormLegend @compressed={{@compressed}} @display={{@display}}>
        {{#if (has-block "legend")}}
          {{yield to="lengend"}}
        {{else}}
          {{@legend}}
        {{/if}}
      </EuiFormLegend>
    {{/if}}
    {{#if (has-block "fieldset")}}
      {{yield to="fieldset"}}
    {{else}}
      {{yield}}
    {{/if}}
  </fieldset>
</template>
