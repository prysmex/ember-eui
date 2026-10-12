import Component from '@glimmer/component';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiLoadingSpinnerStyles,
  euiSpinnerBorderColorsCSS
} from '../utils/eui/styles.generated.ts';

/** A spinning circle, for loading content or actions in progress. */
export interface EuiLoadingSpinnerSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'s'`, `'m'`, `'l'`, `'xl'` or `'xxl'`. Defaults to `'m'`. */
    size?: 's' | 'm' | 'l' | 'xl' | 'xxl';
    /** Native upstream border/highlight color customization. */
    color?: { border?: string; highlight?: string };
  };
}

export default class EuiLoadingSpinner extends Component<EuiLoadingSpinnerSignature> {
  get size() {
    return this.args.size ?? 'm';
  }
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiLoadingSpinnerStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box', animation: 'none' },
      styles.euiLoadingSpinner,
      styles[this.size],
      this.args.color
        ? {
            borderColor: euiSpinnerBorderColorsCSS(
              context.upstream,
              this.args.color
            )
          }
        : undefined
    );
  }
  <template>
    <span
      class="euiBorealisLoadingSpinner {{this.styles}}"
      role="progressbar"
      aria-label="Loading"
      ...attributes
    ></span>
  </template>
}
