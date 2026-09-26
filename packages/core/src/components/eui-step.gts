import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiStepNumber from './eui-step-number.gts';
import EuiTitle from './eui-title.gts';

import type { EuiTitleSignature } from './eui-title';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** One step of an EuiSteps list. */
export interface EuiStepSignature {
  Element: HTMLDivElement;
  Args: {
    /** The step's number, shown in its circle. */
    step: number;
    /** The step's title. */
    title: string;
    /**
     * `'complete'` shows a check, `'incomplete'` a hollow circle,
     * `'disabled'` greys it out. Defaults to the number.
     */
    status?: 'incomplete' | 'complete' | 'disabled';
    /** Size of the title: `'xs'`, `'s'` or `'m'`. Defaults to `'s'`. */
    titleSize?: Exclude<EuiTitleSignature['Args']['size'], 'xxxs' | 'xxs' | 'l'>;
    /** Tag of the title, e.g. `'h3'`. Defaults to `'p'`. */
    headingElement?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'p';
  };
  Blocks: {
    /** The step's instructions, e.g. text, code blocks or EuiSubSteps. */
    default: [];
  };
}

const EuiStep: TemplateOnlyComponent<EuiStepSignature> = <template>
  <div
    class={{classNames
      "euiStep"
      (if (eq @titleSize "xs") "euiStep--small")
      (if (eq @status "disabled") "euiStep-isDisabled")
    }}
    ...attributes
  >
    <div class="euiStep__titleWrapper">
      <EuiStepNumber
        class={{classNames
          "euiStep__circle"
          (if (eq @titleSize "xs") "euiStepNumber--small")
        }}
        @number={{@step}}
        @status={{@status}}
        @titleSize={{argOrDefault @titleSize "s"}}
        @isHollow={{eq @status "incomplete"}}
      />
      <EuiTitle
        @size={{@titleSize}}
        @tagName={{argOrDefault @headingElement "p"}}
        class="euiStep__title"
      >
        {{@title}}
      </EuiTitle>
    </div>
    <div class="euiStep__content">
      {{yield}}
    </div>
  </div>
</template>;

export default EuiStep;
