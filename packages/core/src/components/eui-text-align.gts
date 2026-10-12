import Component from '@glimmer/component';
import { eq } from 'ember-truth-helpers';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { euiTextAlignStyles } from '../utils/eui/styles.generated.ts';

import type { CSSInterpolation } from '@emotion/css/create-instance';

export type EuiTextAlignment = 'left' | 'center' | 'right';

/** @private Shared with EuiText, which composes alignment on its own element. */
export function euiTextAlignCss(
  textAlign: EuiTextAlignment = 'left'
): CSSInterpolation[] {
  return [euiTextAlignStyles.euiTextAlign, euiTextAlignStyles[textAlign]];
}

/** Aligns its text content. */
export interface EuiTextAlignSignature {
  Element: HTMLDivElement | HTMLSpanElement | HTMLParagraphElement;
  Args: {
    /**
     * `'left'`, `'center'` or `'right'`. Defaults to `'left'`. Left and right
     * are logical: they map to `start`/`end`, so they flip in RTL.
     */
    textAlign?: EuiTextAlignment;
    /** `'div'`, `'span'` or `'p'`. Defaults to `'div'`. */
    tagName?: 'div' | 'span' | 'p';
  };
  Blocks: {
    /** The content. */
    default: [];
  };
}

export default class EuiTextAlign extends Component<EuiTextAlignSignature> {
  get classes() {
    return euiClass(
      getEuiThemeContext(this),
      // React's global reset removes paragraph margins; Ember has no reset.
      this.args.tagName === 'p' ? { margin: 0 } : undefined,
      ...euiTextAlignCss(this.args.textAlign)
    );
  }

  <template>
    {{#if (eq @tagName "span")}}
      <span class="euiTextAlign {{this.classes}}" ...attributes>
        {{yield}}
      </span>
    {{else if (eq @tagName "p")}}
      <p class="euiTextAlign {{this.classes}}" ...attributes>
        {{yield}}
      </p>
    {{else}}
      <div class="euiTextAlign {{this.classes}}" ...attributes>
        {{yield}}
      </div>
    {{/if}}
  </template>
}
