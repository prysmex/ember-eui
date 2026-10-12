import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiStepContentStyles,
  euiStepStyles,
  euiStepTitleStyles
} from '../utils/eui/styles.generated.ts';
import EuiStepNumber from './eui-step-number.gts';
import EuiTitle from './eui-title.gts';

import type { EuiStepStatus } from './eui-step-number.gts';

const BOX_SIZING = { boxSizing: 'border-box' } as const;

export type EuiStepTitleSize = 'xxs' | 'xs' | 's' | 'm';

/** One step of an EuiSteps list. */
export interface EuiStepSignature {
  Element: HTMLDivElement;
  Args: {
    /** The step's number, shown in its circle. Defaults to `1` (upstream). */
    step?: number;
    /** The step's title. */
    title: string;
    /**
     * `'complete'` shows a check, `'warning'`/`'danger'` an icon,
     * `'loading'` a spinner, `'incomplete'` a hollow circle, `'current'` an
     * enlarged ringed circle, and `'disabled'` greys it out. Defaults to the
     * number.
     */
    status?: EuiStepStatus;
    /**
     * Size of the title: `'xxs'` (small dot instead of a number), `'xs'`,
     * `'s'` or `'m'`. Defaults to `'s'`.
     */
    titleSize?: EuiStepTitleSize;
    /** Tag of the title, e.g. `'h3'`. Defaults to `'p'`. */
    headingElement?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'p';
  };
  Blocks: {
    /** The step's instructions, e.g. text, code blocks or EuiSubSteps. */
    default: [];
  };
}

export default class EuiStep extends Component<EuiStepSignature> {
  get step(): number {
    return this.args.step ?? 1;
  }

  get titleSize(): EuiStepTitleSize {
    return this.args.titleSize ?? 's';
  }

  get numberSize() {
    return this.titleSize === 'xxs' ? 'none' : this.titleSize;
  }

  get euiTitleSize() {
    return this.titleSize === 'xxs' ? 'xs' : this.titleSize;
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepStyles);
    return `euiStep ${euiClass(
      context,
      BOX_SIZING,
      styles.euiStep,
      styles[this.titleSize]
    )}`;
  }

  @cached
  get titleWrapperClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepTitleStyles);
    return `euiStep__titleWrapper ${euiClass(context, styles.euiStep__titleWrapper)}`;
  }

  @cached
  get titleClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepTitleStyles);
    return `euiStep__title ${euiClass(
      context,
      styles.euiStep__title,
      this.args.status === 'disabled' && styles.isDisabled,
      styles[this.titleSize]
    )}`;
  }

  @cached
  get contentClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepContentStyles);
    return `euiStep__content ${euiClass(
      context,
      BOX_SIZING,
      styles.euiStep__content,
      styles[this.titleSize]
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      <div class={{this.titleWrapperClasses}}>
        <EuiStepNumber
          @number={{this.step}}
          @status={{@status}}
          @titleSize={{this.numberSize}}
        />
        <EuiTitle
          @size={{this.euiTitleSize}}
          @tagName={{if @headingElement @headingElement "p"}}
          class={{this.titleClasses}}
        >
          {{@title}}
        </EuiTitle>
      </div>
      <div class={{this.contentClasses}}>
        {{yield}}
      </div>
    </div>
  </template>
}
