import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiSubStepsStyles } from '../utils/eui/styles.generated.ts';

const BOX_SIZING = { boxSizing: 'border-box' } as const;

/** A shaded box inside an EuiStep for nested instructions. */
export interface EuiSubStepsSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The content. */
    default: [];
  };
}

export default class EuiSubSteps extends Component<EuiSubStepsSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSubStepsStyles);
    return `euiSubSteps ${euiClass(
      context,
      BOX_SIZING,
      styles.euiSubSteps
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{yield}}
    </div>
  </template>
}
