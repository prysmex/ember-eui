import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiDescriptionListTitle from './eui-description-list-title';
import EuiDescriptionListDescription from './eui-description-list-description';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <dl
    class={{classNames
      (if (argOrDefault @compressed false) "euiDescriptionList--compressed")
      type=(argOrDefault @type "row")
      textStyle=(argOrDefault @textStyle "normal")
      align=(argOrDefault @align "left")
      componentName="EuiDescriptionList"
    }}
    ...attributes
  >
    {{#if @listItems}}
      {{#each @listItems as |item|}}
        <EuiDescriptionListTitle class={{@titleProps.className}}>
          {{item.title}}
        </EuiDescriptionListTitle>
        <EuiDescriptionListDescription class={{@descriptionProps.className}}>
          {{item.description}}
        </EuiDescriptionListDescription>
      {{/each}}
    {{else}}
      {{yield}}
    {{/if}}
  </dl>
</template>
