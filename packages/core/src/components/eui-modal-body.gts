import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiModalBodyStyles } from '../utils/eui/styles.generated.ts';

/** The scrolling content of an EuiModal. */
export interface EuiModalBodySignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The content. */
    default: [];
  };
}

export default class EuiModalBody extends Component<EuiModalBodySignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiModalBodyStyles);
    return {
      root: `euiModalBody ${euiClass(
        context,
        { boxSizing: 'border-box' },
        styles.euiModalBody
      )}`,
      overflow: `euiModalBody__overflow ${euiClass(
        context,
        { boxSizing: 'border-box' },
        styles.euiModalBody__overflow
      )}`
    };
  }

  <template>
    <div class={{this.classes.root}} ...attributes>
      <div class={{this.classes.overflow}}>
        {{yield}}
      </div>
    </div>
  </template>
}
