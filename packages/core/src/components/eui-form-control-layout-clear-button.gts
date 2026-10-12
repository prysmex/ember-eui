import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { buttonReset } from '../utils/eui/form-controls.ts';
import { EuiFormControlLayoutClearButtonStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiIcon from './eui-icon.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiCss } from '../utils/eui/styles.ts';
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
  @cached
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
  @cached
  get classes() {
    const { context, styles } = this.styles;
    return euiClass(
      context,
      buttonReset,
      styles.euiFormControlLayoutClearButton,
      styles.size[this.size]
    );
  }
  /**
   * Upstream's `css` on the icon, composed last into EuiIcon's own class so
   * the 8px/6px cross wins over EuiIcon's size (a separate class does not).
   */
  @cached
  get iconCss(): EuiCss {
    const { styles } = this.styles;
    return [
      styles.icon.euiFormControlLayoutClearButton__icon,
      styles.icon.size[this.size]
    ];
  }

  <template>
    <button
      class="euiFormControlLayoutClearButton {{this.classes}}"
      type="button"
      aria-label={{this.label}}
      ...attributes
    >
      <EuiIcon
        @iconClasses="euiFormControlLayoutClearButton__icon"
        @css={{this.iconCss}}
        @type="cross"
        @size={{this.size}}
      />
    </button>
  </template>
}
