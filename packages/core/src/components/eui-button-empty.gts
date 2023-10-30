import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { and, not, or, eq } from 'ember-truth-helpers';
import EuiButtonContent from './eui-button-content';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  {{#let
    (argOrDefault @size "m") (argOrDefault @iconSize "m")
    as |size iconSize|
  }}
    {{#if (and @href (not (or @isLoading @isDisabled)))}}
      <a
        class={{classNames
          (if (or @isLoading @isDisabled) "euiButtonEmpty-isDisabled")
          componentName="EuiButtonEmpty"
          color=(argOrDefault @color "primary")
          size=size
          flush=@flush
        }}
        href={{@href}}
        target={{@target}}
        ...attributes
      >
        <EuiButtonContent
          class="euiButtonEmpty__content {{@contentClasses}}"
          @isLoading={{@isLoading}}
          @iconType={{@iconType}}
          @iconSide={{@iconSide}}
          @iconSize={{if (eq size "xs") "s" iconSize}}
          @iconClasses={{@iconClasses}}
          @useSvg={{@useSvg}}
          @useComponent={{@useComponent}}
          @textClasses={{classNames "euiButtonEmpty__text" @textClasses}}
        >
          {{yield}}
        </EuiButtonContent>
      </a>
    {{else}}
      <button
        class={{classNames
          (if (or @isLoading @isDisabled) "euiButtonEmpty-isDisabled")
          componentName="EuiButtonEmpty"
          color=(argOrDefault @color "primary")
          size=size
          flush=@flush
        }}
        disabled={{or @isLoading @isDisabled @disabled}}
        type={{if @type @type "button"}}
        aria-pressed={{@isSelected}}
        ...attributes
      >
        <EuiButtonContent
          class="euiButtonEmpty__content {{@contentClasses}}"
          @isLoading={{@isLoading}}
          @iconType={{@iconType}}
          @iconSide={{@iconSide}}
          @iconSize={{if (eq size "xs") "s" iconSize}}
          @iconClasses={{@iconClasses}}
          @useSvg={{@useSvg}}
          @useComponent={{@useComponent}}
          @textClasses={{classNames "euiButtonEmpty__text" @textClasses}}
        >
          {{yield}}
        </EuiButtonContent>
      </button>
    {{/if}}
  {{/let}}
</template>
