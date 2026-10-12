import Component from '@glimmer/component';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { euiScreenReaderOnlyStyles } from '../utils/eui/styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';
import type { EuiThemeContext } from '../utils/emotion/context.ts';

/**
 * Upstream `euiScreenReaderOnly` styles, for composing into another
 * component's class: `euiClass(context, …, euiScreenReaderOnlyCss(true))`.
 * The `showOnFocus` variant only hides while nothing in the element has
 * focus (`:not(:focus, :active, :focus-within)`).
 */
export function euiScreenReaderOnlyCss(showOnFocus = false): SerializedStyles {
  return showOnFocus
    ? euiScreenReaderOnlyStyles['euiScreenReaderOnly-showOnFocus']
    : euiScreenReaderOnlyStyles.euiScreenReaderOnly;
}

/**
 * The stable class names for an element hidden by EuiScreenReaderOnly:
 * `euiScreenReaderOnly` (or `euiScreenReaderOnly-showOnFocus`, upstream's
 * label) plus the Emotion class in the provider's cache.
 */
export function euiScreenReaderOnlyClass(
  context: EuiThemeContext,
  showOnFocus = false
): string {
  const root = showOnFocus
    ? 'euiScreenReaderOnly-showOnFocus'
    : 'euiScreenReaderOnly';
  return `${root} ${euiClass(context, euiScreenReaderOnlyCss(showOnFocus))}`;
}

/**
 * Hides its content visually but keeps it for screen readers, e.g. a
 * table caption or the text of an icon-only control. To hide one element
 * without a wrapper, use the `screenReaderOnly` modifier instead.
 */
export interface EuiScreenReaderOnlySignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * Shows the content while something in it has keyboard focus, e.g. a
     * "Skip to content" link.
     */
    showOnFocus?: boolean;
  };
  Blocks: {
    /** The content read by screen readers. */
    default: [];
  };
}

export default class EuiScreenReaderOnly extends Component<EuiScreenReaderOnlySignature> {
  get classes() {
    return euiScreenReaderOnlyClass(
      getEuiThemeContext(this),
      Boolean(this.args.showOnFocus)
    );
  }

  <template>
    <span class={{this.classes}} ...attributes>{{yield}}</span>
  </template>
}
