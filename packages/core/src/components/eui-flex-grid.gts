import argOrDefault from '../helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';
import classNames from '../helpers/class-names';
import { element } from 'ember-element-helper';

<template>
  {{#let (argOrDefault @tagName "div") as |tagName|}}
    {{#if (eq tagName "div")}}
      <div
        class={{classNames
          (unless (eq @responsive false) "euiFlexGrid--responsive")
          componentName="EuiFlexGrid"
          gutterSize=(argOrDefault @gutterSize "l")
          direction=(argOrDefault @direction "row")
          columns=(argOrDefault @columns 0)
        }}
        ...attributes
      >
        {{yield}}
      </div>
    {{else}}
      {{#let (element tagName) as |Element|}}
        <Element
          class={{classNames
            (unless (eq @responsive false) "euiFlexGrid--responsive")
            componentName="EuiFlexGrid"
            gutterSize=(argOrDefault @gutterSize "l")
            direction=(argOrDefault @direction "row")
            columns=(argOrDefault @columns 0)
          }}
          ...attributes
        >
          {{yield}}
        </Element>
      {{/let}}
    {{/if}}
  {{/let}}
</template>
