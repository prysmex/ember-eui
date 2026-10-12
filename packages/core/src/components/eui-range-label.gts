import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiRangeLabelStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

/** @private A min/max label of EuiRange / EuiDualRange (`@showLabels`). */
export interface EuiRangeLabelSignature {
  Element: HTMLLabelElement;
  Args: {
    /** Which end it is for: `'min'` or `'max'`. Defaults to `'max'`. */
    side?: 'min' | 'max';
    /** Disabled styling (half opacity). */
    disabled?: boolean;
  };
  Blocks: {
    default: [];
  };
}

/** Upstream `EuiRangeLabel`: `xs` text with an `s` gap towards the track. */
export default class EuiRangeLabel extends Component<EuiRangeLabelSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiRangeLabelStyles);
    return `euiRangeLabel ${euiClass(
      context,
      styles.euiRangeLabel,
      styles[this.args.side ?? 'max'],
      this.args.disabled && styles.isDisabled
    )}`;
  }

  <template>
    <label class={{this.classes}} ...attributes>{{yield}}</label>
  </template>
}
