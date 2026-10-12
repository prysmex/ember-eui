import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFacetGroupStyles } from '../utils/eui/styles.generated.ts';

/** Lays out `EuiFacetButton`s in a column or in wrapping rows. */
export interface EuiFacetGroupSignature {
  Element: HTMLDivElement | HTMLSpanElement;
  Args: {
    /**
     * `'vertical'` (a column) or `'horizontal'` (wrapping rows).
     * Defaults to `'vertical'`.
     */
    layout?: 'vertical' | 'horizontal';
    /** Space between buttons: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
    gutterSize?: 'none' | 's' | 'm' | 'l';
  };
  Blocks: {
    /** The `EuiFacetButton`s. */
    default: [];
  };
}

export default class EuiFacetGroup extends Component<EuiFacetGroupSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFacetGroupStyles);
    const layout = this.args.layout === 'horizontal' ? 'horizontal' : 'vertical';
    const gutters = styles.gutterSizes[layout];
    return `euiFacetGroup ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiFacetGroup,
      gutters[this.args.gutterSize ?? 'm'] ?? gutters.m,
      styles[layout]
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>{{yield}}</div>
  </template>
}
