import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { guidFor } from '@ember/object/internals';
import classNames from '@ember-eui/core/helpers/class-names';
import { and, not } from 'ember-truth-helpers';

<template>
  {{#let (argOrDefault @id (guidFor)) as |id|}}
    {{#if (and @href (not @disabled))}}
      <a
        id={{id}}
        role="tab"
        aria-selected={{not (not @isSelected)}}
        class={{classNames
          "euiTab"
          (if @isSelected "euiTab-isSelected")
          (if @disabled "euiTab-isDisabled")
        }}
        href={{@href}}
        disabled={{@disabled}}
        ...attributes
      >
        {{#if (has-block "prepend")}}
          <span class="euiTab__prepend">
            {{yield to="prepend"}}
          </span>
        {{/if}}

        <span class="euiTab__content">
          {{yield}}
        </span>

        {{#if (has-block "append")}}
          <span class="euiTab__append">
            {{yield to="append"}}
          </span>
        {{/if}}
      </a>
    {{else}}
      <button
        id={{id}}
        role="tab"
        aria-selected={{not (not @isSelected)}}
        type="button"
        class={{classNames
          "euiTab"
          (if @isSelected "euiTab-isSelected")
          (if @disabled "euiTab-isDisabled")
        }}
        disabled={{@disabled}}
        ...attributes
      >
        {{#if (has-block "prepend")}}
          <span class="euiTab__prepend">
            {{yield to="prepend"}}
          </span>
        {{/if}}

        <span class="euiTab__content">
          {{yield}}
        </span>

        {{#if (has-block "append")}}
          <span class="euiTab__append">
            {{yield to="append"}}
          </span>
        {{/if}}
      </button>
    {{/if}}
  {{/let}}
</template>
