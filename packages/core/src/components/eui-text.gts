import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { and, not } from 'ember-truth-helpers';
import EuiTextAlign from './eui-text-align';
import EuiTextColor from './eui-text-color';

<template>
  <div
    class={{classNames
      (unless (argOrDefault @grow true) "euiText--constrainedWidth")
      componentName="EuiText"
      size=(argOrDefault @size "m")
    }}
    ...attributes
  >
    {{#if (and @textAlign @color)}}
      {{#let (component EuiTextAlign) as |Align|}}
        {{#let (component EuiTextColor) as |Color|}}
          <Align @textAlign={{@textAlign}}>
            <Color @color={{@color}} @tagName="div">
              {{yield}}
            </Color>
          </Align>
        {{/let}}
      {{/let}}
    {{else if (and @textAlign (not @color))}}
      {{#let (component EuiTextAlign) as |Align|}}
        <Align @textAlign={{@textAlign}}>
          {{yield}}
        </Align>
      {{/let}}
    {{else if (and (not @textAlign) @color)}}
      {{#let (component EuiTextColor) as |Color|}}
        <Color @color={{@color}} @tagName="div">
          {{yield}}
        </Color>
      {{/let}}
    {{else}}
      {{yield}}
    {{/if}}
  </div>
</template>
