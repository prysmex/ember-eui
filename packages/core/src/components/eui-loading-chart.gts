import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiLoadingChartBarStyles,
  euiLoadingChartStyles
} from '../utils/eui/styles.generated.ts';

import type EuiI18n from '../services/eui-i18n.ts';

const BARS = [0, 1, 2, 3];

/** Animated bars, for a chart or visualization that is loading. */
export interface EuiLoadingChartSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'m'`, `'l'` or `'xl'`. Defaults to `'m'`. */
    size?: 'm' | 'l' | 'xl';
    /**
     * @deprecated Has no effect: latest EUI draws every chart loader with
     * the neutral `loadingChartMonoBackground` tokens.
     */
    mono?: boolean;
  };
}

export default class EuiLoadingChart extends Component<EuiLoadingChartSignature> {
  @service declare euiI18n: EuiI18n;

  get size() {
    return this.args.size ?? 'm';
  }

  get label() {
    return this.euiI18n.lookupToken('euiLoadingStrings.ariaLabel', 'Loading');
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiLoadingChartStyles);
    return `euiLoadingChart ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiLoadingChart,
      styles[this.size]
    )}`;
  }

  @cached
  get barClasses() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiLoadingChartBarStyles
    );
    return `euiLoadingChart__bar ${euiClass(
      context,
      styles.euiLoadingChart__bar,
      styles[this.size]
    )}`;
  }

  <template>
    <span
      class={{this.classes}}
      role="progressbar"
      aria-label={{this.label}}
      ...attributes
    >
      {{#each BARS}}<span class={{this.barClasses}}></span>{{/each}}
    </span>
  </template>
}
