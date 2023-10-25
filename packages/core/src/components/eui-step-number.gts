import classNames from '@ember-eui/core/helpers/class-names';
import { eq } from 'ember-truth-helpers';
import EuiIcon from '@ember-eui/core/components/eui-icon';
import EuiLoadingSpinner from '@ember-eui/core/components/eui-loading-spinner';
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
