import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';

<template>
  {{#if (eq @tagName "div")}}
    <div
      class={{classNames
        componentName="EuiTextColor"
        color=(argOrDefault @color "default")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  {{else}}
    <span
      class={{classNames
        componentName="EuiTextColor"
        color=(argOrDefault @color "default")
      }}
      ...attributes
    >
      {{yield}}
    </span>
  {{/if}}
</template>
