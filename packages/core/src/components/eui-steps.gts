import Component from '@glimmer/component';
import { provide } from 'ember-provide-consume-context';

import spreadAttributes from '../-private/eui-spread-attributes.ts';
import { EUI_STEPS_CONTEXT } from '../-private/eui-steps-context.ts';
import EuiStep from './eui-step.gts';

import type { EuiStepsContext } from '../-private/eui-steps-context.ts';
import type { EuiStepStatus } from './eui-step-number.gts';
import type { EuiStepHeadingElement, EuiStepTitleSize } from './eui-step.gts';

/**
 * One entry of `@steps` (upstream `EuiContainedStepProps`): the args of an
 * `EuiStep` without `step`, which counts up from `@firstStepNumber`.
 */
export interface EuiContainedStep {
  /** The step's title. */
  title: string;
  /** Text content of the step. Use the `<:step>` block for markup. */
  children?: string;
  /** See `EuiStep`'s `@status`. */
  status?: EuiStepStatus;
  /** Overrides the list's `@titleSize` for this step. */
  titleSize?: EuiStepTitleSize;
  /** Overrides the list's `@headingElement` for this step. */
  headingElement?: EuiStepHeadingElement;
  /** Class of the step's root element. */
  className?: string;
  /**
   * Other keys (`data-test-subj`, `id`, `aria-*`, …) become attributes of
   * the step's root element, as upstream spreads them. The `<:step>` block
   * receives the whole entry.
   */
  [key: string]: unknown;
}

/** Keys of a step that are args of `EuiStep`, not attributes. */
const STEP_ARGS = [
  'title',
  'children',
  'status',
  'titleSize',
  'headingElement',
  'step'
] as const;

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
    /**
     * The steps as data (upstream's `steps`): one `EuiStep` is rendered per
     * entry, numbered from `@firstStepNumber`. A step's content is its
     * `children` text, or the `<:step>` block. Without it, the default
     * block's `EuiStep`s are rendered.
     */
    steps?: EuiContainedStep[];
  };
  Blocks: {
    /** The `EuiStep`s, numbered automatically by their order. */
    default: [];
    /**
     * With `@steps`: the content of each step (upstream's `children`
     * node), yielded the step and its index. Wins over `children`.
     */
    step: [step: EuiContainedStep, index: number];
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

  stepNumber = (index: number): number => this.firstStepNumber + index;

  <template>
    <div class="euiSteps" ...attributes>
      {{#if @steps}}
        {{#each @steps as |step index|}}
          <EuiStep
            class={{step.className}}
            {{spreadAttributes step STEP_ARGS}}
            @step={{this.stepNumber index}}
            @title={{step.title}}
            @status={{step.status}}
            @titleSize={{step.titleSize}}
            @headingElement={{step.headingElement}}
          >
            {{#if (has-block "step")}}
              {{yield step index to="step"}}
            {{else}}
              {{step.children}}
            {{/if}}
          </EuiStep>
        {{/each}}
      {{else}}
        {{yield}}
      {{/if}}
    </div>
  </template>
}
