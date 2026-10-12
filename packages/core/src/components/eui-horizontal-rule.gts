import Component from '@glimmer/component';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiHorizontalRuleStyles } from '../utils/eui/styles.generated.ts';

/** A divider line between sections. */
export interface EuiHorizontalRuleSignature {
  Element: HTMLHRElement;
  Args: {
    /**
     * Space above and below: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'`, `'xl'`
     * or `'xxl'`. Defaults to `'m'`.
     */
    margin?: 'none' | 'xs' | 's' | 'm' | 'l' | 'xl' | 'xxl';
    /** Width: `'full'`, `'half'` or `'quarter'`. Defaults to `'full'`. */
    size?: 'full' | 'half' | 'quarter';
  };
}

export default class EuiHorizontalRule extends Component<EuiHorizontalRuleSignature> {
  get size() {
    return this.args.size ?? 'full';
  }
  get margin() {
    return this.args.margin ?? 'm';
  }
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiHorizontalRuleStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box', margin: 0 },
      styles.euiHorizontalRule,
      styles[this.size],
      styles[this.margin]
    );
  }
  <template>
    <hr class="euiBorealisHorizontalRule {{this.styles}}" ...attributes />
  </template>
}
