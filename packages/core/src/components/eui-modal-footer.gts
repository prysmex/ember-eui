import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiModalFooterStyles } from '../utils/eui/styles.generated.ts';

/** The bottom of an EuiModal, with its buttons (right aligned). */
export interface EuiModalFooterSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The buttons, e.g. an `EuiButtonEmpty` to cancel and an `EuiButton @fill={{true}}`. */
    default: [];
  };
}

export default class EuiModalFooter extends Component<EuiModalFooterSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiModalFooterStyles);
    return `euiModalFooter ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiModalFooter
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{yield}}
    </div>
  </template>
}
