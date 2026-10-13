import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { provide } from 'ember-provide-consume-context';

import spreadAttributes from '../-private/eui-spread-attributes.ts';
import { EUI_STEPS_HORIZONTAL_CONTEXT } from '../-private/eui-steps-horizontal-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiStepsHorizontalStyles } from '../utils/eui/styles.generated.ts';
import EuiStepHorizontal from './eui-step-horizontal.gts';

import type {
  EuiStepsHorizontalContext,
  EuiStepsHorizontalSize
} from '../-private/eui-steps-horizontal-context.ts';
import type { EuiStepStatus } from './eui-step-number.gts';

/**
 * One entry of `@steps` (upstream `EuiStepHorizontalProps` without `step`,
 * which is the entry's position, from 1).
 */
export interface EuiStepsHorizontalStep {
  /** The step's title. */
  title?: string;
  /** Called when the step is clicked (not while disabled). */
  onClick?: (event: MouseEvent) => void;
  /** Disables the step. */
  disabled?: boolean;
  /** See `EuiStepHorizontal`'s `@status`. Defaults to `'incomplete'`. */
  status?: EuiStepStatus;
  /** Overrides the list's `@size` for this step. */
  size?: EuiStepsHorizontalSize;
  /** Overrides the step's generated accessible label. */
  'aria-label'?: string;
  /** Class of the step's button. */
  className?: string;
  /**
   * Other keys (`data-test-subj`, `id`, `aria-*`, …) become attributes of
   * the step's button, as upstream spreads them.
   */
  [attribute: string]: unknown;
}

/** Keys of a step that are args of `EuiStepHorizontal`, not attributes. */
const STEP_ARGS = ['title', 'onClick', 'disabled', 'status', 'size'] as const;

const LIST_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  listStyle: 'none'
} as const;

/** A horizontal progress of steps (`EuiStepHorizontal`), e.g. a wizard's header. */
export interface EuiStepsHorizontalSignature {
  Element: HTMLOListElement;
  Args: {
    /**
     * Size of the steps' numbers and connecting lines: `'xs'` (16px dot),
     * `'s'` (24px) or `'m'` (32px). Defaults to `'m'`.
     */
    size?: EuiStepsHorizontalSize;
    /**
     * The steps as data (upstream's `steps`): one `EuiStepHorizontal` per
     * entry, numbered by position. Without it, the block's
     * `EuiStepHorizontal`s are rendered.
     */
    steps?: EuiStepsHorizontalStep[];
  };
  Blocks: {
    /** The `EuiStepHorizontal`s. */
    default: [];
  };
}

export default class EuiStepsHorizontal
  extends Component<EuiStepsHorizontalSignature>
  implements EuiStepsHorizontalContext
{
  @provide(EUI_STEPS_HORIZONTAL_CONTEXT)
  get stepsContext(): EuiStepsHorizontalContext {
    return this;
  }

  get size(): EuiStepsHorizontalSize {
    return this.args.size ?? 'm';
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepsHorizontalStyles);
    return `euiStepsHorizontal ${euiClass(
      context,
      // Scoped stand-in for React's global list reset.
      LIST_RESET,
      styles.euiStepsHorizontal
    )}`;
  }

  <template>
    <ol class={{this.classes}} ...attributes>
      {{#if @steps}}
        {{#each @steps as |step index|}}
          <EuiStepHorizontal
            class={{step.className}}
            {{spreadAttributes step STEP_ARGS}}
            @step={{stepNumber index}}
            @title={{step.title}}
            @status={{step.status}}
            @disabled={{step.disabled}}
            @size={{step.size}}
            @onStepClick={{step.onClick}}
          />
        {{/each}}
      {{else}}
        {{yield}}
      {{/if}}
    </ol>
  </template>
}

function stepNumber(index: number): number {
  return index + 1;
}
