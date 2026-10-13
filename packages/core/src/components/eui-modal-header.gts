import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiModalHeaderStyles } from '../utils/eui/styles.generated.ts';

/** The top of an EuiModal. */
export interface EuiModalHeaderSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** An `EuiModalHeaderTitle`. */
    default: [];
  };
}

export default class EuiModalHeader extends Component<EuiModalHeaderSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiModalHeaderStyles);
    return `euiModalHeader ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiModalHeader
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{yield}}
    </div>
  </template>
}
