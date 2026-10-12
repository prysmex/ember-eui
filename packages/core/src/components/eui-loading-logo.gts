import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiLoadingLogoStyles } from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';

import type EuiI18n from '../services/eui-i18n.ts';

/** A bouncing logo, for loading a whole page or app. */
export interface EuiLoadingLogoSignature {
  Element: HTMLSpanElement;
  Args: {
    /** The logo, anything `EuiIcon`'s `@type` accepts. Defaults to `'logoKibana'`. */
    logo?: string;
    /** `'m'`, `'l'` or `'xl'`. Defaults to `'m'`. */
    size?: 'm' | 'l' | 'xl';
  };
}

export default class EuiLoadingLogo extends Component<EuiLoadingLogoSignature> {
  @service declare euiI18n: EuiI18n;

  get size() {
    return this.args.size ?? 'm';
  }

  get label() {
    return this.euiI18n.lookupToken('euiLoadingStrings.ariaLabel', 'Loading');
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiLoadingLogoStyles
    );
  }

  @cached
  get classes() {
    return `euiLoadingLogo ${euiClass(
      getEuiThemeContext(this),
      this.styles.euiLoadingLogo,
      this.styles[this.size]
    )}`;
  }

  @cached
  get iconClasses() {
    return `euiLoadingLogo__icon ${euiClass(
      getEuiThemeContext(this),
      this.styles.euiLoadingLogo__icon
    )}`;
  }

  <template>
    <span
      class={{this.classes}}
      role="progressbar"
      aria-label={{this.label}}
      ...attributes
    >
      <span class={{this.iconClasses}}>
        <EuiIcon @type={{if @logo @logo "logoKibana"}} @size={{this.size}} />
      </span>
    </span>
  </template>
}
