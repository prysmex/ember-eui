import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';

import { eq } from 'ember-truth-helpers';
import EuiStepNumber from './eui-step-number.gts';
import EuiTitle from './eui-title.gts';
import type { EuiTitleSignature } from './eui-title.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiStepSignature {
  Element: HTMLDivElement;
  Args: {
    step: number;
    title: string;
    status: 'incomplete' | 'complete' | 'disabled';
    titleSize: Exclude<EuiTitleSignature['Args']['size'], 'xxxs' | 'xxs' | 'l'>;
    headingElement: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'p';
  };
  Blocks: {
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
