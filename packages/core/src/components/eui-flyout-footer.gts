import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFlyoutFooterStyles } from '../utils/eui/styles.generated.ts';

/** The bottom bar of an EuiFlyout, usually with its buttons. */
export interface EuiFlyoutFooterSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** Usually an `EuiFlexGroup` with close/cancel and primary buttons. */
    default: [];
  };
}

export default class EuiFlyoutFooter extends Component<EuiFlyoutFooterSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutFooterStyles);
    return `euiFlyoutFooter ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiFlyoutFooter
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{yield}}
    </div>
  </template>
}
