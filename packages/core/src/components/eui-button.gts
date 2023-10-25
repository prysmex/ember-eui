import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { or, and, eq, not } from 'ember-truth-helpers';
import classify from 'ember-cli-string-helpers/helpers/classify';
import { concat } from '@ember/helper';
import { element } from 'ember-element-helper';
import EuiButtonContent from '@ember-eui/core/components/eui-button-content';
import classNames from '@ember-eui/core/helpers/class-names';

<template>
  {{#let
    (argOrDefault @baseClassName "euiButton")
    (if
      @element
      @element
      (if (and @href (not (or @isLoading @isDisabled))) "a" "button")
    )
    as |baseClassName theElement|
  }}
    {{#let (element theElement) as |Element|}}
      <Element
        class={{classNames
          (if @fill (concat baseClassName "--fill"))
          (if @fullWidth (concat baseClassName "--fullWidth"))
          (if
            (or @isLoading @isDisabled @disabled)
            (concat baseClassName "-isDisabled")
          )
          componentName=(classify baseClassName)
          color=(argOrDefault @color "primary")
          size=@size
        }}
        disabled={{or @isLoading @isDisabled @disabled}}
        href={{@href}}
        target={{@target}}
        aria-pressed={{if @isSelected "true" null}}
        type={{if (eq theElement "button") (argOrDefault @type "button") null}}
        ...attributes
      >
        <EuiButtonContent
          class={{classNames "euiButton__content" @contentClasses}}
          @isLoading={{@isLoading}}
          @iconType={{@iconType}}
          @iconSize={{@iconSize}}
          @iconSide={{@iconSide}}
          @iconClasses={{@iconClasses}}
          @useSvg={{@useSvg}}
          @useComponent={{@useComponent}}
          @textClasses={{classNames "euiButton__text" @textClasses}}
        >
          {{yield}}
        </EuiButtonContent>
      </Element>
    {{/let}}
  {{/let}}
</template>
