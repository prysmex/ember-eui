import Component from '@glimmer/component';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiSkeletonTextStyles } from '../utils/eui/styles.generated.ts';

import type EuiI18n from '../services/eui-i18n.ts';

/**
 * Animated placeholder lines shown while text content loads. Drawn with
 * upstream EuiSkeletonText's styles (EuiLoadingContent's latest successor).
 */
export interface EuiLoadingContentSignature {
  Element: HTMLSpanElement;
  Args: {
    /** Number of lines, 1 to 10. Defaults to `1`. */
    lines?: number;
    /**
     * Line height of the text being replaced: `'m'`, `'s'`, `'xs'` (EuiText
     * sizes) or `'relative'` (`1em`). Defaults to `'m'`.
     */
    size?: 'm' | 's' | 'xs' | 'relative';
    /** Extra classes for each line. */
    singleLineClasses?: string;
  };
  Blocks: {
    /** Unused. */
    default: [];
  };
}

function lineCount(lines: number | undefined): number {
  if (lines === undefined) return 1;
  return Math.min(10, Math.max(1, lines));
}

export default class EuiLoadingContent extends Component<EuiLoadingContentSignature> {
  @service declare euiI18n: EuiI18n;

  get lines() {
    return Array.from({ length: lineCount(this.args.lines) });
  }

  get label() {
    return this.euiI18n.lookupToken('euiLoadingStrings.ariaLabel', 'Loading');
  }

  get lineClasses() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSkeletonTextStyles);
    return [
      'euiLoadingContent__singleLine',
      this.args.singleLineClasses,
      euiClass(
        context,
        { boxSizing: 'border-box' },
        styles.euiSkeletonText,
        styles[this.args.size ?? 'm']
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  <template>
    <span
      class="euiLoadingContent"
      role="progressbar"
      aria-label={{this.label}}
      ...attributes
    >
      {{#each this.lines}}<span class={{this.lineClasses}}></span>{{/each}}
    </span>
  </template>
}
