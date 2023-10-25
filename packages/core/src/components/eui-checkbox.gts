import { modifier } from 'ember-modifier';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import { and, or, not } from 'ember-truth-helpers';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import optional from 'ember-composable-helpers/helpers/optional';

const indeterminateModifier = modifier(function invalidateIndeterminate(
  element: HTMLInputElement,
  [indeterminate]: [boolean]
) {
  if (element) {
    element.indeterminate = indeterminate;
  }
});

<template>
  {{#let
    (and (has-block "label") (not (argOrDefault @isFakeLabelBlock false)))
    (argOrDefault @id (unique-id))
    as |hasLabelBlock id|
  }}
    {{#let
      (classNames
        (if @icon "euiCheckbox--withIcon")
        (if (not (or hasLabelBlock @label)) "euiCheckbox--noLabel")
        (if @compressed "euiCheckbox--compressed")
        "euiCheckbox"
        @className
        @containerClass
      )
      as |classes|
    }}
      <div class={{classes}}>
        <input
          class="euiCheckbox__input"
          type="checkbox"
          id={{id}}
          checked={{@checked}}
          disabled={{@disabled}}
          ...attributes
          {{indeterminateModifier @indeterminate @checked}}
          {{didInsert (optional @inputRef)}}
        />
        <div class="euiCheckbox__square"></div>
        {{#if (or hasLabelBlock @label)}}
          <label
            class={{classNames "euiCheckbox__label" @labelProps.className}}
            for={{id}}
          >
            {{#if hasLabelBlock}}
              {{yield to="label"}}
            {{else}}
              {{@label}}
            {{/if}}
          </label>
        {{/if}}
      </div>
    {{/let}}
  {{/let}}
</template>
