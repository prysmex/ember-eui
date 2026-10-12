import Component from '@glimmer/component';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFormErrorTextStyles } from '../utils/eui/styles.generated.ts';

/** An error message under a control; EuiFormRow renders these from `@error`. */
export interface EuiFormErrorTextSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The message. */
    default: [];
  };
}

export default class EuiFormErrorText extends Component<EuiFormErrorTextSignature> {
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFormErrorTextStyles);
    return euiClass(
      context,
      // React's global styles supply the box model and body font.
      {
        boxSizing: 'border-box',
        fontFamily: context.upstream.euiTheme.font.family
      },
      styles.euiFormErrorText
    );
  }

  <template>
    <div
      class="euiFormErrorText {{this.classes}}"
      aria-live="polite"
      ...attributes
    >
      {{yield}}
    </div>
  </template>
}
