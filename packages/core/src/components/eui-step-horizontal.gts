import classNames from '@ember-eui/core/helpers/class-names';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';
import EuiStepNumber from '@ember-eui/core/components/eui-step-number';
import { on } from '@ember/modifier';
import optional from 'ember-composable-helpers/helpers/optional';

<template>
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
