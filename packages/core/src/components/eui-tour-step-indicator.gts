import Component from '@glimmer/component';
import { inject as service } from '@ember/service';

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

  get classes(): string {
    return this.args.status
      ? `euiTourStepIndicator euiTourStepIndicator--${this.args.status}`
      : 'euiTourStepIndicator';
  }

  <template>
    <li class={{this.classes}} aria-label={{this.label}} ...attributes>
      {{#if this.iconLabel}}
        <EuiIcon
          class="euiStepNumber__icon"
          @type="dot"
          @color={{if (isActive @status) "success" "subdued"}}
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
