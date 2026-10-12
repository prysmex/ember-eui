import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiSpacerStyles } from '../utils/eui/styles.generated.ts';

/** Vertical space between elements. */
export interface EuiSpacerSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `'xs'` (4px), `'s'` (8px), `'m'` (16px), `'l'` (24px), `'xl'` (32px)
     * or `'xxl'` (40px). Defaults to `'l'`.
     */
    size?: 'xs' | 's' | 'm' | 'l' | 'xl' | 'xxl';
  };
}

export default class EuiSpacer extends Component<EuiSpacerSignature> {
  get size() {
    return this.args.size ?? 'l';
  }
  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSpacerStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiSpacer,
      styles[this.size]
    );
  }
  <template>
    <div class="euiBorealisSpacer {{this.styles}}" ...attributes></div>
  </template>
}
