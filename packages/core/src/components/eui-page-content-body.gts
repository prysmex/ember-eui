import Component from '@glimmer/component';

import style from 'ember-style-modifier/modifiers/style';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiPageBoxSizing,
  euiPagePadding,
  euiPageRestrictWidthStyle,
  isRestricted
} from '../utils/eui/page-layout.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { euiPageSectionContentStyles } from '../utils/eui/styles.generated.ts';

import type { EuiPagePaddingSize } from '../utils/eui/page-layout.ts';

/**
 * The content of an EuiPageContent. Styled as upstream's
 * `EuiPageSection` content (`euiPageSection__content`).
 */
export interface EuiPageContentBodySignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Max width of the content, centered: `true` for EUI's default
     * (1200px), a number in px, or any CSS width. Defaults to `false`
     * (no limit).
     */
    restrictWidth?: boolean | number | string;
    /**
     * Padding on every side: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or
     * `'xl'`. Defaults to `'none'`.
     */
    paddingSize?: EuiPagePaddingSize;
    /** Inline styles, merged with the max width. */
    style?: {
      [key: string]: string;
    };
  };
  Blocks: {
    /** The content. */
    default: [];
  };
}

export default class EuiPageContentBody extends Component<EuiPageContentBodySignature> {
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = euiPageSectionContentStyles();
    return euiClass(
      context,
      euiPageBoxSizing,
      styles.euiPageSection__content,
      euiPagePadding(context.upstream, this.args.paddingSize),
      isRestricted(this.args.restrictWidth) && styles.restrictWidth
    );
  }

  get inlineStyle() {
    return euiPageRestrictWidthStyle(this.args.restrictWidth, this.args.style);
  }

  <template>
    <div
      class="euiPageContentBody {{this.classes}}"
      {{style this.inlineStyle}}
      ...attributes
    >
      {{yield}}
    </div>
  </template>
}
