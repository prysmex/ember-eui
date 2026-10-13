import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { layoutBoxReset } from '../utils/eui/form-controls.ts';
import { euiRangeWrapperStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

import type { EuiCss } from '../utils/eui/styles.ts';

/** @private Wraps the parts of EuiRange / EuiDualRange. */
export interface EuiRangeWrapperSignature {
  Element: HTMLDivElement;
  Args: {
    /** Stretches to the container's width (otherwise the 400px form width). */
    fullWidth?: boolean;
    /** Compressed height (32px instead of 40px). */
    compressed?: boolean;
    /** @private Styles composed last into the wrapper's class (upstream `css`). */
    css?: EuiCss;
  };
  Blocks: {
    default: [];
  };
}

/** Upstream `EuiRangeWrapper`: a flex row at the form control height. */
export default class EuiRangeWrapper extends Component<EuiRangeWrapperSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiRangeWrapperStyles);
    return `euiRangeWrapper ${euiClass(
      context,
      layoutBoxReset,
      styles.euiRangeWrapper,
      this.args.compressed ? styles.compressed : styles.uncompressed,
      this.args.fullWidth ? styles.fullWidth : styles.formWidth,
      this.args.css
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{yield}}
    </div>
  </template>
}
