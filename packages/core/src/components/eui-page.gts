import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiPageBoxSizing,
  euiPagePadding,
  euiPageRestrictWidthStyle,
  isRestricted
} from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiBackgroundColor,
  euiPageStyles
} from '../utils/eui/styles.generated.ts';

import type { EuiPagePaddingSize } from '../utils/eui/page-layout.ts';

/** The outermost layout of a page: holds an optional `EuiPageSideBar` and an `EuiPageBody`. See also EuiPageTemplate. */
export interface EuiPageSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Max width of the page, centered: `true` for EUI's default (1200px),
     * a number in px, or any CSS width. Defaults to `false` (no limit).
     */
    restrictWidth?: boolean | number | string;
    /**
     * Padding around the page: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or
     * `'xl'`. Defaults to `'none'`.
     */
    paddingSize?: EuiPagePaddingSize;
    /** Grows to fill its flex parent (`flex-grow: 1`). Defaults to `true`. */
    grow?: boolean;
    /**
     * `'row'` puts an `EuiPageSideBar` beside the body from the theme's `m`
     * breakpoint up and stacks them below it; `'column'` always stacks them.
     * Defaults to `'row'`.
     */
    direction?: 'row' | 'column';
    /**
     * Background: `'transparent'`, `'plain'`, `'subdued'`, `'highlighted'`,
     * `'accent'`, `'accentSecondary'`, `'primary'`, `'success'`, `'warning'`
     * or `'danger'`. Defaults to `'transparent'`.
     */
    color?: string;
    /** Inline styles, merged with the max width. */
    style?: Record<string, string>;
  };
  Blocks: {
    /** `EuiPageSideBar` and `EuiPageBody`. */
    default: [];
  };
}

/** Upstream `EuiPage` (`euiPageStyles`) on the Borealis theme. */
export default class EuiPage extends Component<EuiPageSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const upstream = context.upstream;
    const styles = useEuiBorealisStyles(context, euiPageStyles);
    // Same order as upstream's `stylesCSS`.
    return euiClass(
      context,
      euiPageBoxSizing,
      styles.euiPage,
      styles[this.args.direction ?? 'row'],
      { backgroundColor: euiBackgroundColor(upstream, this.args.color ?? 'transparent') },
      (this.args.grow ?? true) && styles.grow,
      euiPagePadding(upstream, this.args.paddingSize ?? 'none'),
      isRestricted(this.args.restrictWidth) && styles.restrictWidth
    );
  }

  get inlineStyle() {
    return euiPageRestrictWidthStyle(this.args.restrictWidth, this.args.style);
  }

  <template>
    <div
      class="euiPage {{this.classes}}"
      ...attributes
      {{style this.inlineStyle}}
    >
      {{yield}}
    </div>
  </template>
}
