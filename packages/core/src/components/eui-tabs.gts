import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';

<template>
  {{#let
    (if (eq @display "condensed") false (argOrDefault @bottomBorder true))
    as |bottomBorder|
  }}
    <div
      role="tablist"
      class={{classNames
        (if (argOrDefault @expand false) "euiTabs--expand")
        (if bottomBorder "euiTabs--bottomBorder")
        @className
        componentName="EuiTabs"
        display=(argOrDefault @display "default")
        size=(argOrDefault @size "m")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  {{/let}}
</template>
