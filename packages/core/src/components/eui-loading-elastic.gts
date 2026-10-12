import Component from '@glimmer/component';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { euiLoadingElasticStyles } from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';

import type EuiI18n from '../services/eui-i18n.ts';

/** The Elastic logo, animated, for a full page or app that is loading. */
export interface EuiLoadingElasticSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'m'`, `'l'`, `'xl'` or `'xxl'`. Defaults to `'m'`. */
    size?: 'm' | 'l' | 'xl' | 'xxl';
  };
}

export default class EuiLoadingElastic extends Component<EuiLoadingElasticSignature> {
  @service declare euiI18n: EuiI18n;

  get label() {
    return this.euiI18n.lookupToken('euiLoadingStrings.ariaLabel', 'Loading');
  }

  get classes() {
    const styles = euiLoadingElasticStyles;
    return `euiLoadingElastic ${euiClass(
      getEuiThemeContext(this),
      styles.euiLoadingElastic
    )}`;
  }

  <template>
    <span
      class={{this.classes}}
      role="progressbar"
      aria-label={{this.label}}
      ...attributes
    >
      <EuiIcon @type="logoElastic" @size={{if @size @size "m"}} />
    </span>
  </template>
}
