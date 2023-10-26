import argOrDefault from '../helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';
import classNames from '../helpers/class-names';
import { element } from 'ember-element-helper';

<template>
  {{#let (argOrDefault @tagName "div") as |tagName|}}
    {{#if (eq tagName "div")}}
      <div
        class={{classNames componentName="EuiFlexItem" grow=@grow}}
        ...attributes
      >
        {{yield}}
      </div>
    {{else if (eq tagName "span")}}
      <span
        class={{classNames componentName="EuiFlexItem" grow=@grow}}
        ...attributes
      >
        {{yield}}
      </span>
    {{else}}
      {{#let (element tagName) as |Element|}}
        <Element
          class={{classNames componentName="EuiFlexItem" grow=@grow}}
          ...attributes
        >
          {{yield}}
        </Element>
      {{/let}}
    {{/if}}
  {{/let}}
</template>
