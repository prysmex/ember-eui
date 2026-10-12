import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFormHelpTextStyles } from '../utils/eui/styles.generated.ts';

/** Help text under a control; EuiFormRow renders it from `@helpText`. */
export interface EuiFormHelpTextSignature {
  Element: HTMLDivElement;
  Args: {
    /** Id, to reference from the control's `aria-describedby`. */
    id?: string;
  };
  Blocks: {
    /** The text. */
    default: [];
  };
}

export default class EuiFormHelpText extends Component<EuiFormHelpTextSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFormHelpTextStyles);
    return euiClass(
      context,
      // React's global styles supply the box model and body font.
      {
        boxSizing: 'border-box',
        fontFamily: context.upstream.euiTheme.font.family
      },
      styles.euiFormHelpText
    );
  }

  <template>
    <div class="euiFormHelpText {{this.classes}}" id={{@id}} ...attributes>
      {{yield}}
    </div>
  </template>
}
