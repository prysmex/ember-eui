import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';

import { euiStepsContext } from '../-private/eui-steps-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiStepContentStyles,
  euiStepStyles,
  euiStepTitleStyles
} from '../utils/eui/styles.generated.ts';
import EuiStepNumber from './eui-step-number.gts';
import EuiTitle from './eui-title.gts';

import type { EuiStepStatus } from './eui-step-number.gts';

const BOX_SIZING = { boxSizing: 'border-box' } as const;

export type EuiStepHeadingElement = 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'p';

export type EuiStepTitleSize = 'xxs' | 'xs' | 's' | 'm';

/** One step of an EuiSteps list. */
export interface EuiStepSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * The step's number, shown in its circle. Inside an `EuiSteps` it
     * defaults to the step's position (from `@firstStepNumber`), otherwise `1`.
     */
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
    headingElement?: EuiStepHeadingElement;
  };
  Blocks: {
    /** The step's instructions, e.g. text, code blocks or EuiSubSteps. */
    default: [];
  };
}

export default class EuiStep extends Component<EuiStepSignature> {
  /** Position among the sibling steps of the parent `EuiSteps` (UI state). */
  @tracked position = 0;

  get stepsContext() {
    return euiStepsContext(this);
  }

  /** Counts the preceding sibling steps, and follows steps added or removed. */
  trackPosition = modifier((element: Element) => {
    const parent = element.parentElement;
    if (!parent) return;
    const update = () => {
      let index = 0;
      for (const child of Array.from(parent.children)) {
        if (child === element) break;
        if (child.classList.contains('euiStep')) index++;
      }
      this.position = index;
    };
    update();
    const observer = new MutationObserver(update);
    observer.observe(parent, { childList: true });
    return () => observer.disconnect();
  });

  get step(): number {
    return (
      this.args.step ??
      (this.stepsContext
        ? this.stepsContext.firstStepNumber + this.position
        : 1)
    );
  }

  get titleSize(): EuiStepTitleSize {
    return this.args.titleSize ?? this.stepsContext?.titleSize ?? 's';
  }

  get headingElement(): EuiStepHeadingElement {
    return this.args.headingElement ?? this.stepsContext?.headingElement ?? 'p';
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
  get titleCss(): EuiCss {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepTitleStyles);
    return [
      styles.euiStep__title,
      this.args.status === 'disabled' && styles.isDisabled,
      styles[this.titleSize]
    ];
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
    <div class={{this.classes}} {{this.trackPosition}} ...attributes>
      <div class={{this.titleWrapperClasses}}>
        <EuiStepNumber
          @number={{this.step}}
          @status={{@status}}
          @titleSize={{this.numberSize}}
        />
        <EuiTitle
          @size={{this.euiTitleSize}}
          @tagName={{this.headingElement}}
          class="euiStep__title"
          @css={{this.titleCss}}
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
