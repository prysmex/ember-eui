import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiTitleStyles } from '../utils/eui/styles.generated.ts';
import TextBlock from './text-block.gts';

import type { TextBlockSignature } from './text-block';

/**
 * A heading styled with EUI's type scale:
 * `<EuiTitle @size="s" @tagName="h3">Settings</EuiTitle>`.
 */
export interface EuiTitleSignature {
  Element: HTMLHeadingElement | HTMLParagraphElement | HTMLLegendElement;
  Args: {
    /**
     * The heading tag EuiTitle renders: `'h1'`–`'h6'`, `'p'` or `'legend'`.
     * Defaults to `'h2'`. Put the text directly inside EuiTitle; do not wrap
     * it in another heading.
     */
    tagName?: TextBlockSignature['Args']['tagName'];
    /**
     * `'xxxs'`, `'xxs'`, `'xs'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`.
     * Size is independent of the tag: pick the tag for the page outline and
     * the size for the look.
     */
    size?: 'xxxs' | 'xxs' | 'xs' | 's' | 'm' | 'l';
    /** `'uppercase'` for all caps. */
    textTransform?: 'uppercase';
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The title's text. */
    default: [];
  };
}

export default class EuiTitle extends Component<EuiTitleSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTitleStyles);
    return euiClass(
      context,
      // React's global reset zeroes heading/legend boxes and sets the font.
      {
        boxSizing: 'border-box',
        margin: 0,
        padding: 0,
        fontFamily: context.upstream.euiTheme.font.family
      },
      styles.euiTitle,
      this.args.textTransform ? styles[this.args.textTransform] : undefined,
      styles[this.args.size ?? 'm'],
      this.args.css
    );
  }

  <template>
    <TextBlock
      @tagName={{if @tagName @tagName "h2"}}
      class="euiTitle {{this.classes}}"
      ...attributes
    >
      {{yield}}
    </TextBlock>
  </template>
}
