import { on } from '@ember/modifier';

import optional from 'ember-composable-helpers/helpers/optional';
import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiStepNumber from './eui-step-number.gts';
import type { EuiStepNumberSignature } from './eui-step-number.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiStepHorizontalSignature {
  Element: HTMLButtonElement;
  Args: {
    /**
     * The title of the step
     */
    title?: string;
    /**
     * The number of the step
     */
    step?: number;
    /**
     * Whether or not the step is selected
     */
    isSelected?: boolean;
    /**
     * Whether or not the step is complete
     */
    isComplete?: boolean;
    /**
     * Whether or not the step is disabled
     */
    disabled?: boolean;
    /**
     * The status of the step
     */
    status?: EuiStepNumberSignature['Args']['status'];
    /**
     * A callback for when the step is clicked
     */
    onStepClick?: (event: MouseEvent) => void;
  };
}

const EuiStepHorizontal: TemplateOnlyComponent<EuiStepHorizontalSignature> =
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
      <li
        class="euiStepHorizontal__item"
        aria-current={{if @isSelected "step"}}
      >
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
            {{!@glint-expect-error}}
            @status={{status}}
            @number={{@step}}
          />
          <span class="euiStepHorizontal__title">
            {{@title}}
          </span>
        </button>
      </li>
    {{/let}}
  </template>;

export default EuiStepHorizontal;
