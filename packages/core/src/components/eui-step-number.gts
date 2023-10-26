import classNames from '../helpers/class-names';
import { eq } from 'ember-truth-helpers';
import EuiIcon from './eui-icon';
import EuiLoadingSpinner from './eui-loading-spinner';
import screenReaderOnly from '@ember-eui/core/modifiers/screen-reader-only';

<template>
  {{#let (if (eq @titleSize "xs") "s" "m") as |iconSize|}}
    <span
      class={{classNames
        (if @isHollow "euiStepNumber-isHollow")
        componentName="EuiStepNumber"
        type=@status
      }}
      ...attributes
    >
      {{#if (eq @status "complete")}}
        <EuiIcon
          @iconClasses="euiStepNumber__icon"
          @type="check"
          @size={{iconSize}}
        />
      {{else if (eq @status "warning")}}
        <EuiIcon
          @iconClasses="euiStepNumber__icon"
          @type="warning"
          @size={{iconSize}}
        />
      {{else if (eq @status "danger")}}
        <EuiIcon
          @iconClasses="euiStepNumber__icon"
          @type="cross"
          @size={{iconSize}}
        />
      {{else if (eq @status "loading")}}
        <span {{screenReaderOnly}}>{{@stepAriaLabel}}</span>
        <EuiLoadingSpinner
          class="euiStepNumber__loader"
          @size={{if (eq iconSize "s") "l" "xl"}}
        />
      {{else}}
        <span {{screenReaderOnly}}>{{@stepAriaLabel}}</span>
        <span class="euiStepNumber__number" aria-hidden="true">
          {{@number}}
        </span>
      {{/if}}
    </span>
  {{/let}}
</template>
