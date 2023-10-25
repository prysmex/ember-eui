import { or } from 'ember-truth-helpers';
import EuiFormLegend from '@ember-eui/core/components/eui-form-legend';

<template>
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
