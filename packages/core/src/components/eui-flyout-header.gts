import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFlyoutHeaderStyles } from '../utils/eui/styles.generated.ts';

/** The top of an EuiFlyout, usually with an `EuiTitle`. */
export interface EuiFlyoutHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    /** Adds a border between the header and the body. */
    hasBorder?: boolean;
  };
  Blocks: {
    /** The title, e.g. `<EuiTitle @size="m" @tagName="h2">Details</EuiTitle>`. */
    default: [];
  };
}

export default class EuiFlyoutHeader extends Component<EuiFlyoutHeaderSignature> {
  /**
   * The flyout pads a bordered header's bottom through upstream's
   * `[class*='euiFlyoutHeader-hasBorder']`, which matches the Emotion class
   * name built from the slot labels.
   */
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutHeaderStyles);
    return `euiFlyoutHeader ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiFlyoutHeader,
      this.args.hasBorder ? styles.hasBorder : undefined
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{yield}}
    </div>
  </template>
}
