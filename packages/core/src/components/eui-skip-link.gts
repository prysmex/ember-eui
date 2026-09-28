import { concat } from '@ember/helper';

import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import EuiButton from './eui-button.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

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
     * Give that element `tabindex="-1"` if it is not focusable itself.
     */
    destinationId: string;
    /**
     * Where the link shows when focused: `'static'` (in place),
     * `'fixed'` (top left of the viewport) or `'absolute'`. Defaults to
     * `'static'`.
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

const EuiSkipLink: TemplateOnlyComponent<EuiSkipLinkSignature> = <template>
  <EuiButton
    class={{concat "euiSkipLink euiSkipLink--" (if @position @position "static")}}
    @href={{concat "#" @destinationId}}
    @size="s"
    @fill={{true}}
    tabindex={{if (isFixed @position) 0 @tabIndex}}
    {{screenReaderOnly true}}
    ...attributes
  >
    {{yield}}
  </EuiButton>
</template>;

function isFixed(position: string | undefined): boolean {
  return position === 'fixed';
}

export default EuiSkipLink;
