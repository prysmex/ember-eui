import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { provide } from 'ember-provide-consume-context';

import { EUI_STEPS_HORIZONTAL_CONTEXT } from '../-private/eui-steps-horizontal-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiStepsHorizontalStyles } from '../utils/eui/styles.generated.ts';

import type {
  EuiStepsHorizontalContext,
  EuiStepsHorizontalSize
} from '../-private/eui-steps-horizontal-context.ts';

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
      {{yield}}
    </ol>
  </template>
}
