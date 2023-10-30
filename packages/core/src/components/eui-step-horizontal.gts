import { on } from '@ember/modifier';

import optional from 'ember-composable-helpers/helpers/optional';
import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiStepNumber from './eui-step-number';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  {{#let
    (if
      @disabled
      "disabled"
      (if
        @isComplete
        "complete"
        (if @isSelected "current" (argOrDefault @status "incomplete"))
      )
    )
    as |status|
  }}
    <li class="euiStepHorizontal__item" aria-current={{if @isSelected "step"}}>
      <button
        type="button"
        class={{classNames
          "euiStepHorizontal"
          (if (eq status "current") "euiStepHorizontal-isSelected")
          (if (eq status "complete") "euiStepHorizontal-isComplete")
          (if (eq status "incomplete") "euiStepHorizontal-isIncomplete")
          (if (eq status "disabled") "euiStepHorizontal-isDisabled")
        }}
        title={{@title}}
        disabled={{@disabled}}
        ...attributes
        {{on "click" (optional @onStepClick)}}
      >
        <EuiStepNumber
          class="euiStepHorizontal__number"
          @status={{status}}
          @number={{@step}}
        />
        <span class="euiStepHorizontal__title">
          {{@title}}
        </span>
      </button>
    </li>
  {{/let}}
</template>
