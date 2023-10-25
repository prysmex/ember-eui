import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';
import classNames from '@ember-eui/core/helpers/class-names';

<template>
  {{#if (eq @tagName "span")}}
    <span
      class={{classNames
        (unless (eq @responsive false) "euiFlexGroup--responsive")
        (if @wrap "euiFlexGroup--wrap")
        componentName="EuiFlexGroup"
        gutterSize=(argOrDefault @gutterSize "l")
        alignItems=(argOrDefault @alignItems "stretch")
        justifyContent=(argOrDefault @justifyContent "flexStart")
        direction=(argOrDefault @direction "row")
      }}
      ...attributes
    >
      {{yield}}
    </span>
  {{else}}
    <div
      class={{classNames
        (unless (eq @responsive false) "euiFlexGroup--responsive")
        (if @wrap "euiFlexGroup--wrap")
        componentName="EuiFlexGroup"
        gutterSize=(argOrDefault @gutterSize "l")
        alignItems=(argOrDefault @alignItems "stretch")
        justifyContent=(argOrDefault @justifyContent "flexStart")
        direction=(argOrDefault @direction "row")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  {{/if}}
</template>
