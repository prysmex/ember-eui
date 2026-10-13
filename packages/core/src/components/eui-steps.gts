import Component from '@glimmer/component';
import { provide } from 'ember-provide-consume-context';

import { EUI_STEPS_CONTEXT } from '../-private/eui-steps-context.ts';

import type { EuiStepsContext } from '../-private/eui-steps-context.ts';
import type { EuiStepHeadingElement, EuiStepTitleSize } from './eui-step.gts';

/** A vertical list of numbered steps (`EuiStep`), e.g. setup instructions. */
export interface EuiStepsSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * The number the first step starts from; the following steps count up
     * from it. A step with its own `@step` keeps that number. Defaults to `1`.
     */
    firstStepNumber?: number;
    /**
     * Tag of the steps' titles, e.g. `'h3'`. A step's own `@headingElement`
     * wins. Defaults to `'p'`.
     */
    headingElement?: EuiStepHeadingElement;
    /**
     * Title size of the steps: `'xxs'`, `'xs'`, `'s'` or `'m'`. A step's own
     * `@titleSize` wins. Defaults to `'s'`.
     */
    titleSize?: EuiStepTitleSize;
  };
  Blocks: {
    /** The `EuiStep`s, numbered automatically by their order. */
    default: [];
  };
}

export default class EuiSteps
  extends Component<EuiStepsSignature>
  implements EuiStepsContext
{
  @provide(EUI_STEPS_CONTEXT)
  get stepsContext(): EuiStepsContext {
    return this;
  }

  get firstStepNumber(): number {
    return this.args.firstStepNumber ?? 1;
  }

  get titleSize() {
    return this.args.titleSize;
  }

  get headingElement(): EuiStepHeadingElement | undefined {
    return this.args.headingElement;
  }

  <template>
    <div class="euiSteps" ...attributes>
      {{yield}}
    </div>
  </template>
}
