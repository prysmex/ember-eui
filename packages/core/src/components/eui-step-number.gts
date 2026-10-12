import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiScreenReaderOnly,
  euiStepNumberContentStyles,
  euiStepNumberStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';

import type EuiI18nService from '../services/eui-i18n.ts';

const BOX_SIZING = { boxSizing: 'border-box' } as const;
const SCREEN_READER_ONLY = euiScreenReaderOnly();

/** Upstream step statuses. */
export const STEP_STATUSES = [
  'incomplete',
  'disabled',
  'loading',
  'warning',
  'danger',
  'complete',
  'current'
] as const;

export type EuiStepStatus = (typeof STEP_STATUSES)[number];

/** Upstream step number sizes (`none` is the xxs title's dot). */
export type EuiStepNumberSize = 'none' | 'xs' | 's' | 'm';

type Labels = Record<EuiStepStatus | 'step', [string, string, string, string]>;

/**
 * Upstream `step_strings`: `[token, default, simpleToken, simpleDefault]`;
 * the simple variant is used without a title.
 */
export const STEP_LABELS: Labels = {
  step: ['euiStepStrings.step', 'Step {number}: {title}', 'euiStepStrings.simpleStep', 'Step {number}'],
  complete: ['euiStepStrings.complete', 'Step {number}: {title} is complete', 'euiStepStrings.simpleComplete', 'Step {number} is complete'],
  warning: ['euiStepStrings.warning', 'Step {number}: {title} has warnings', 'euiStepStrings.simpleWarning', 'Step {number} has warnings'],
  danger: ['euiStepStrings.errors', 'Step {number}: {title} has errors', 'euiStepStrings.simpleErrors', 'Step {number} has errors'],
  incomplete: ['euiStepStrings.incomplete', 'Step {number}: {title} is incomplete', 'euiStepStrings.simpleIncomplete', 'Step {number} is incomplete'],
  disabled: ['euiStepStrings.disabled', 'Step {number}: {title} is disabled', 'euiStepStrings.simpleDisabled', 'Step {number} is disabled'],
  loading: ['euiStepStrings.loading', 'Step {number}: {title} is loading', 'euiStepStrings.simpleLoading', 'Step {number} is loading'],
  current: ['euiStepStrings.current', 'Current step {number}: {title}', 'euiStepStrings.simpleCurrent', 'Current step is {number}']
};

/** Looks up a step's accessible status text (upstream `useI18n*Step`). */
export function stepLabel(
  i18n: EuiI18nService,
  status: EuiStepStatus | undefined,
  number: number | string | undefined,
  title?: string
): string {
  const [token, fallback, simpleToken, simpleFallback] =
    STEP_LABELS[status && status in STEP_LABELS ? status : 'step'];
  return title
    ? i18n.lookupToken(token, fallback, { number, title })
    : i18n.lookupToken(simpleToken, simpleFallback, { number });
}

const ICONS = { complete: 'check', warning: 'warning', danger: 'cross' } as const;
const ICON_SIZES = { none: 's', xs: 's', s: 'm', m: 'm' } as const;
const SPINNER_SIZES = { none: 'm', xs: 'l', s: 'xl', m: 'xl' } as const;

/** The circle with a step's number or status icon. */
export interface EuiStepNumberSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * The number of the step
     */
    number?: number | string;
    /**
     * `'complete'` (check), `'warning'` (warning icon), `'danger'` (cross),
     * `'loading'` (spinner), `'incomplete'` (hollow), `'disabled'` or
     * `'current'` (enlarged, ringed); without one the number is shown.
     */
    status?: EuiStepStatus;
    /**
     * Size of the step's title: `'m'`/`'s'` (32px circle), `'xs'` (24px) or
     * `'none'`/`'xxs'` (16px, no number). Defaults to `'s'`.
     */
    titleSize?: EuiStepNumberSize | 'xxs';
    /**
     * @deprecated Use `@status="incomplete"`. Treated as `incomplete` when
     * there is no `@status`.
     */
    isHollow?: boolean;
    /**
     * Screen reader text; defaults to upstream's status text, e.g.
     * "Step 2 is complete".
     */
    stepAriaLabel?: string;
  };
}

export default class EuiStepNumber extends Component<EuiStepNumberSignature> {
  @service declare euiI18n: EuiI18nService;

  get status(): EuiStepStatus | undefined {
    return this.args.status ?? (this.args.isHollow ? 'incomplete' : undefined);
  }

  get size(): EuiStepNumberSize {
    const size = this.args.titleSize ?? 's';
    return size === 'xxs' ? 'none' : size;
  }

  get iconType(): string | undefined {
    const status = this.status;
    return status && status in ICONS
      ? ICONS[status as keyof typeof ICONS]
      : undefined;
  }

  get isLoading(): boolean {
    return this.status === 'loading';
  }

  get label(): string {
    return (
      this.args.stepAriaLabel ??
      stepLabel(this.euiI18n, this.status, this.args.number)
    );
  }

  get iconSize() {
    return ICON_SIZES[this.size];
  }

  get spinnerSize() {
    return SPINNER_SIZES[this.size];
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepNumberStyles);
    const status = this.status;
    return `euiStepNumber ${euiClass(
      context,
      BOX_SIZING,
      styles.euiStepNumber,
      styles[this.size],
      status && styles[status]
    )}`;
  }

  @cached
  get iconClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStepNumberContentStyles);
    const status = this.status;
    return `euiStepNumber__icon ${euiClass(
      context,
      styles.euiStepNumber__icon,
      status === 'warning'
        ? styles.warning[this.size]
        : status === 'complete' || status === 'danger'
          ? styles[status]
          : undefined,
      this.size === 'none' && styles.none
    )}`;
  }

  @cached
  get srClass(): string {
    return euiClass(getEuiThemeContext(this), SCREEN_READER_ONLY);
  }

  <template>
    <span class={{this.classes}} ...attributes>
      {{#if this.iconType}}
        <EuiIcon
          class={{this.iconClasses}}
          @type={{this.iconType}}
          @size={{this.iconSize}}
          @aria-label={{this.label}}
        />
      {{else}}
        <span class={{this.srClass}}><span>{{this.label}}</span></span>
        {{#if this.isLoading}}
          <EuiLoadingSpinner
            class="euiStepNumber__loader"
            @size={{this.spinnerSize}}
          />
        {{else if (notNone this.size)}}
          <span class="euiStepNumber__number" aria-hidden="true">
            {{@number}}
          </span>
        {{/if}}
      {{/if}}
    </span>
  </template>
}

function notNone(size: EuiStepNumberSize): boolean {
  return size !== 'none';
}
