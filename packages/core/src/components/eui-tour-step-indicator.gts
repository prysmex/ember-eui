import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import EuiIcon from './eui-icon.gts';

import type EuiI18n from '../services/eui-i18n';

/** One dot of a tour's progress: `'complete'`, `'active'` or `'incomplete'`. */
export interface EuiTourStepIndicatorSignature {
  Element: HTMLLIElement;
  Args: {
    /** The step's number (1-based). */
    number: number;
    /** `'complete'`, `'active'` or `'incomplete'`. */
    status?: 'complete' | 'active' | 'incomplete';
  };
}

/** Upstream's static indicator style, plus a scoped list item reset. */
const INDICATOR = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  display: 'inline-block',
  label: 'EuiTourStepIndicator'
} as const;

export default class EuiTourStepIndicator extends Component<EuiTourStepIndicatorSignature> {
  @service declare euiI18n: EuiI18n;

  get label(): string {
    return this.euiI18n.lookupToken('euiTourStepIndicator.ariaLabel', 'Step {number} {status}', {
      number: this.args.number,
      status: this.args.status ?? ''
    });
  }

  get iconLabel(): string | undefined {
    const { status } = this.args;

    if (status === 'active') return this.euiI18n.lookupToken('euiTourStepIndicator.isActive', 'active');
    if (status === 'complete') return this.euiI18n.lookupToken('euiTourStepIndicator.isComplete', 'complete');
    if (status === 'incomplete') {
      return this.euiI18n.lookupToken('euiTourStepIndicator.isIncomplete', 'incomplete');
    }

    return undefined;
  }

  @cached
  get classes(): string {
    return `euiTourStepIndicator ${euiClass(getEuiThemeContext(this), INDICATOR)}`;
  }

  /** Upstream: theme `tourStepIndicatorActiveColor` / `…InactiveColor`. */
  @cached
  get iconColor(): string {
    const { components } = getEuiThemeContext(this).upstream.euiTheme;

    return this.args.status === 'active'
      ? components.tourStepIndicatorActiveColor
      : components.tourStepIndicatorInactiveColor;
  }

  <template>
    <li class={{this.classes}} aria-label={{this.label}} ...attributes>
      {{#if this.iconLabel}}
        <EuiIcon
          @type="dot"
          @color={{this.iconColor}}
          aria-label={{this.iconLabel}}
          aria-current={{if (isActive @status) "step"}}
        />
      {{/if}}
    </li>
  </template>
}

function isActive(status?: string): boolean {
  return status === 'active';
}
