import { hash } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { focusTrap } from 'ember-focus-trap';
import onKey from 'ember-keyboard/modifiers/on-key';
import style from 'ember-style-modifier/modifiers/style';
import { and, eq, notEq } from 'ember-truth-helpers';

import { preventDefault, stopPropagation } from '../-private/event-helpers.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import inlineStyles from '../helpers/inline-styles.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiOverlayMask from './eui-overlay-mask.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A dialog over the page, with a mask behind it. Render it only while
 * open: `{{#if this.isOpen}}<EuiModal @onClose={{…}}>…</EuiModal>{{/if}}`.
 * For yes/no questions use EuiConfirmModal.
 */
export interface EuiModalSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Called by the close button, Escape and (with `@clickOutsideToClose`)
     * clicks on the mask. Stop rendering the modal here.
     */
    onClose?: (e: Event) => void;
    /**
     * `true` for EUI's default max width, or any CSS width (e.g. `'800px'`).
     * Defaults to the content's width.
     */
    maxWidth?: boolean | string;
    /** Clicking the mask around the modal calls `@onClose`. */
    clickOutsideToClose?: boolean;
    /** Traps keyboard focus inside the modal. Defaults to `true`. */
    isFocusTrapActive?: boolean;
    /** Focuses the modal itself when it opens. Defaults to `true`. */
    shouldSelfFocus?: boolean;
    /** Pauses the focus trap, e.g. while a nested popover has focus. */
    isFocusTrapPaused?: boolean;
    /**
     * Options for the focus trap (focus-trap library), e.g.
     * `{ initialFocus: '#name' }` to focus a field when it opens.
     */
    focusTrapOptions?: {
      allowOutsideClick?: boolean;
      clickOutsideDeactivates?: boolean;
      initialFocus?: string | HTMLElement | (() => HTMLElement);
      fallbackFocus?: string | HTMLElement | (() => HTMLElement);
      escapeDeactivates?: boolean;
      returnFocusOnDeactivate?: boolean;
      preventScroll?: boolean;
    };
  };
  Blocks: {
    /** `EuiModalHeader`, `EuiModalBody` and `EuiModalFooter`. */
    default: [];
  };
}

const EuiModal: TemplateOnlyComponent<EuiModalSignature> = <template>
  {{#let
    (if
      (and @maxWidth (notEq @maxWidth true))
      (inlineStyles
        componentName="EuiModal" componentArgs=(hash maxWidth=@maxWidth)
      )
      (hash)
    )
    as |inlineStyles|
  }}
    <EuiOverlayMask
      @onClick={{if @clickOutsideToClose (optional @onClose) (optional)}}
    >
      <div
        class={{classNames
          "euiModal"
          (if (eq @maxWidth true) "euiModal--maxWidth-default")
        }}
        tabindex="0"
        ...attributes
        {{style inlineStyles}}
        {{focusTrap
          isActive=(argOrDefault @isFocusTrapActive true)
          shouldSelfFocus=(argOrDefault @shouldSelfFocus true)
          isPaused=(argOrDefault @isFocusTrapPaused false)
          focusTrapOptions=(argOrDefault @focusTrapOptions (hash))
        }}
        {{onKey
          "Escape"
          (preventDefault (stopPropagation (optional @onClose)))
        }}
      >
        <EuiButtonIcon
          class="euiModal__closeIcon"
          @iconType="cross"
          @color="text"
          {{on "click" (optional @onClose)}}
        />
        <div class="euiModal__flex">
          {{yield}}
        </div>
      </div>
    </EuiOverlayMask>
  {{/let}}
</template>;

export default EuiModal;
