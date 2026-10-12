import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { isTabbable } from 'tabbable';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiSkipLinkStyles } from '../utils/eui/styles.generated.ts';
import EuiButton from './eui-button.gts';
import { euiScreenReaderOnlyCss } from './eui-screen-reader-only.gts';

/**
 * A link for keyboard users to jump past repeated content (like the
 * header) to the main content. It is hidden until focused, so put it
 * first in the page.
 */
export interface EuiSkipLinkSignature {
  Element: HTMLElement;
  Args: {
    /**
     * Id of the element to jump to (without `#`), e.g. `'main-content'`.
     * A destination that is not focusable is made focusable (`tabindex="-1"`)
     * while it has focus.
     */
    destinationId: string;
    /**
     * Query selector(s) to jump to when no element has `@destinationId`,
     * tried in order. Defaults to `'main'`.
     */
    fallbackDestination?: string | string[];
    /**
     * Scrolls to and focuses the destination itself instead of following
     * the `#id` link (e.g. for apps with hash routing). The URL hash does
     * not change.
     */
    overrideLinkBehavior?: boolean;
    /**
     * Where the link shows when focused: `'static'` (in place),
     * `'fixed'` (top left of the viewport) or `'absolute'` (position it
     * yourself). Defaults to `'static'`.
     */
    position?: 'static' | 'fixed' | 'absolute';
    /** `tabindex` of the link; a fixed link always gets `0`. */
    tabIndex?: number;
  };
  Blocks: {
    /** The link text, e.g. "Skip to main content". */
    default: [];
  };
}

export default class EuiSkipLink extends Component<EuiSkipLinkSignature> {
  get position() {
    return this.args.position ?? 'static';
  }

  get tabIndex() {
    return this.position === 'fixed' ? 0 : this.args.tabIndex;
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSkipLinkStyles);
    return `euiSkipLink ${euiClass(
      context,
      euiScreenReaderOnlyCss(true),
      styles.euiSkipLink,
      this.position !== 'static' ? styles[this.position] : undefined
    )}`;
  }

  /** Upstream's click handling: fallbacks, scrolling and focus. */
  onClick = (event: MouseEvent) => {
    const { destinationId, overrideLinkBehavior } = this.args;
    const fallback = this.args.fallbackDestination ?? 'main';
    let destination: HTMLElement | null =
      document.getElementById(destinationId);
    const hasValidId = Boolean(destination);

    if (!destination && fallback) {
      for (const selector of Array.isArray(fallback) ? fallback : [fallback]) {
        destination = document.querySelector<HTMLElement>(selector);
        if (destination) break;
      }
    }

    if ((overrideLinkBehavior || !hasValidId) && destination) {
      event.preventDefault();

      const destinationY = destination.getBoundingClientRect().top;
      const halfOfViewportHeight = window.innerHeight / 2;
      if (
        destinationY >= halfOfViewportHeight ||
        window.scrollY >= destinationY + halfOfViewportHeight
      ) {
        destination.scrollIntoView();
      }

      if (!isTabbable(destination)) {
        const target = destination;
        target.tabIndex = -1;
        target.addEventListener('blur', () => target.removeAttribute('tabindex'), {
          once: true
        });
      }
      destination.focus({ preventScroll: true });
    }
  };

  <template>
    <EuiButton
      class={{this.classes}}
      @href="#{{@destinationId}}"
      @size="s"
      @fill={{true}}
      tabindex={{this.tabIndex}}
      {{on "click" this.onClick}}
      ...attributes
    >
      {{yield}}
    </EuiButton>
  </template>
}
