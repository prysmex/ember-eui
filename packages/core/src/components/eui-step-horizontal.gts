import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { euiStepsHorizontalSize } from '../-private/eui-steps-horizontal-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiStepHorizontalNumberStyles,
  euiStepHorizontalStyles,
  euiStepHorizontalTitleStyles,
  euiStepsHorizontalStyles
} from '../utils/eui/styles.generated.ts';
import EuiStepNumber, { stepLabel } from './eui-step-number.gts';

import type { EuiStepsHorizontalSize } from '../-private/eui-steps-horizontal-context.ts';
import type EuiI18nService from '../services/eui-i18n.ts';
import type { EuiStepStatus } from './eui-step-number.gts';

const ITEM_RESET = { boxSizing: 'border-box', margin: 0, padding: 0 } as const;

// The number size map is not 1 to 1: a small step uses the xs number.
const NUMBER_SIZES = { xs: 'none', s: 'xs', m: 'm' } as const;

/** One step of an EuiStepsHorizontal, a clickable button in an `<li>`. */
export interface EuiStepHorizontalSignature {
  Element: HTMLButtonElement;
  Args: {
    /**
     * The title of the step
     */
    title?: string;
    /**
     * The number of the step. Defaults to `1`.
     */
    step?: number;
    /**
     * Marks the current step (status `'current'`, `aria-current="step"`).
     * Same as `@status="current"`.
     */
    isSelected?: boolean;
    /** Same as `@status="complete"`. */
    isComplete?: boolean;
    /**
     * Disables the step (status `'disabled'`): clicks are ignored.
     */
    disabled?: boolean;
    /**
     * `'complete'`, `'current'`, `'incomplete'`, `'disabled'`, `'loading'`,
     * `'warning'` or `'danger'`. Defaults to `'incomplete'`.
     */
    status?: EuiStepStatus;
    /**
     * `'xs'`, `'s'` or `'m'`. Defaults to the EuiStepsHorizontal's
     * `@size`, else `'m'`.
     */
    size?: EuiStepsHorizontalSize;
    /**
     * A callback for when the step is clicked (not called while disabled)
     */
    onStepClick?: (event: MouseEvent) => void;
  };
}

export default class EuiStepHorizontal extends Component<EuiStepHorizontalSignature> {
  @service declare euiI18n: EuiI18nService;

  get step(): number {
    return this.args.step ?? 1;
  }

  get status(): EuiStepStatus {
    const { disabled, isComplete, isSelected, status } = this.args;
    if (disabled) return 'disabled';
    if (isComplete) return 'complete';
    if (isSelected) return 'current';
    return status ?? 'incomplete';
  }

  get isDisabled(): boolean {
    return this.status === 'disabled';
  }

  get size(): EuiStepsHorizontalSize {
    return euiStepsHorizontalSize(this, this.args.size);
  }

  get numberSize() {
    return NUMBER_SIZES[this.size];
  }

  get label(): string {
    return stepLabel(this.euiI18n, this.status, this.step, this.args.title);
  }

  @cached
  get itemClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepsHorizontalStyles);
    return `euiStepsHorizontal__item euiStepHorizontal__item ${euiClass(
      context,
      ITEM_RESET,
      styles.euiStepsHorizontal__item
    )}`;
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const theme = context.upstream.euiTheme;
    const styles = useEuiBorealisStyles(context, euiStepHorizontalStyles);
    return `euiStepHorizontal ${euiClass(
      context,
      // Scoped stand-in for React's global button reset.
      {
        boxSizing: 'border-box',
        margin: 0,
        border: 'none',
        background: 'none',
        color: 'inherit',
        fontFamily: theme.font.family,
        fontSize: 'inherit',
        '&::before, &::after': { boxSizing: 'border-box' }
      },
      styles.euiStepHorizontal,
      styles[this.size],
      this.isDisabled ? styles.disabled : styles.enabled
    )}`;
  }

  @cached
  get numberClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepHorizontalNumberStyles);
    return `euiStepHorizontal__number ${euiClass(
      context,
      styles.euiStepHorizontal__number
    )}`;
  }

  @cached
  get titleClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepHorizontalTitleStyles);
    return `euiStepHorizontal__title ${euiClass(
      context,
      styles.euiStepHorizontal__title,
      this.isDisabled && styles.disabled
    )}`;
  }

  onClick = (event: MouseEvent) => {
    if (!this.isDisabled) this.args.onStepClick?.(event);
  };

  <template>
    <li
      class={{this.itemClasses}}
      aria-current={{if (isCurrent this.status) "step"}}
    >
      <button
        type="button"
        class={{this.classes}}
        aria-label={{this.label}}
        aria-disabled={{if this.isDisabled "true"}}
        title={{@title}}
        disabled={{@disabled}}
        data-step-status={{this.status}}
        ...attributes
        {{on "click" this.onClick}}
      >
        <EuiStepNumber
          class={{this.numberClasses}}
          @status={{this.status}}
          @number={{this.step}}
          @titleSize={{this.numberSize}}
        />
        <span class={{this.titleClasses}}>
          {{@title}}
        </span>
      </button>
    </li>
  </template>
}

function isCurrent(status: EuiStepStatus): boolean {
  return status === 'current';
}
