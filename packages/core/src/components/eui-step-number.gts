import classNames from '../helpers/class-names';
import { eq } from 'ember-truth-helpers';
import EuiIcon from './eui-icon.gts';
import type { EuiIconSignature } from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import screenReaderOnly from '../modifiers/screen-reader-only';
import { helper } from '@ember/component/helper';
import type { EuiStepSignature } from './eui-step.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

import type { statusToClassMap } from '../utils/css-mappings/eui-step-number';

export interface EuiStepNumberSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * The number of the step
     */
    number?: number | string;
    /**
     * The status of the step
     */
    status?: keyof typeof statusToClassMap;
    /**
     * The size of the step
     */
    titleSize?: EuiStepSignature['Args']['titleSize'];
    /**
     * Whether the step is hollow
     */
    isHollow?: boolean;
    /**
     * The aria-label for the step
     */
    stepAriaLabel?: string;
  };
}

const getIconSize = helper(
  ([titleSize]: [EuiStepNumberSignature['Args']['titleSize']]): Exclude<
    EuiIconSignature['Args']['size'],
    'l' | 'xl' | 'xxl'
  > => (titleSize === 'xs' ? 's' : 'm')
);

const EuiStepNumber: TemplateOnlyComponent<EuiStepNumberSignature> = <template>
  {{#let (getIconSize @titleSize) as |iconSize|}}
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
</template>;

export default EuiStepNumber;
