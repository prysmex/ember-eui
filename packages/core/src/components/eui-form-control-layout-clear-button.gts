import Component from '@glimmer/component';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { buttonReset } from '../utils/eui/form-controls.ts';
import { EuiFormControlLayoutClearButtonStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiIcon from './eui-icon.gts';

import type EuiI18n from '../services/eui-i18n';
import type { CommonArgs } from './common.ts';

export type EuiFormControlLayoutClearButtonArgs = CommonArgs & {
  /** `'s'` (12px) or `'m'` (16px). Defaults to `'m'`. */
  size?: 's' | 'm';
  /**
   * Accessible label of the button. Defaults to the
   * `euiFormControlLayoutClearButton.label` token ("Clear input").
   */
  label?: string;
};

/** @private The clear ("x") button of EuiFormControlLayout; add `{{on "click" …}}`. */
export interface EuiFormControlLayoutClearButtonSignature {
  Element: HTMLButtonElement;
  Args: EuiFormControlLayoutClearButtonArgs;
}

export default class EuiFormControlLayoutClearButton extends Component<EuiFormControlLayoutClearButtonSignature> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  get size(): 's' | 'm' {
    return this.args.size === 's' ? 's' : 'm';
  }
  get label() {
    return (
      this.args.label ??
      this.euiI18n.lookupToken(
        'euiFormControlLayoutClearButton.label',
        'Clear input'
      )
    );
  }
  get styles() {
    const context = getEuiThemeContext(this);
    return {
      context,
      styles: useEuiBorealisStyles(
        context,
        EuiFormControlLayoutClearButtonStyles
      )
    };
  }
  get classes() {
    const { context, styles } = this.styles;
    return euiClass(
      context,
      buttonReset,
      styles.euiFormControlLayoutClearButton,
      styles.size[this.size]
    );
  }
  get iconClasses() {
    const { context, styles } = this.styles;
    return euiClass(
      context,
      styles.icon.euiFormControlLayoutClearButton__icon,
      styles.icon.size[this.size]
    );
  }

  <template>
    <button
      class="euiFormControlLayoutClearButton {{this.classes}}"
      type="button"
      aria-label={{this.label}}
      ...attributes
    >
      <EuiIcon
        @iconClasses="euiFormControlLayoutClearButton__icon {{this.iconClasses}}"
        @type="cross"
        @size={{this.size}}
      />
    </button>
  </template>
}
