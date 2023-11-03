import classNames from '../helpers/class-names';
import { eq, and, notEq } from 'ember-truth-helpers';
import argOrDefault from '../helpers/arg-or-default';
import { on } from '@ember/modifier';
import EuiOverlayMask from './eui-overlay-mask.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import { hash } from '@ember/helper';
import inlineStyles from '../helpers/inline-styles';
import focusTrapModifier from 'ember-focus-trap';
import onKey from 'ember-keyboard/modifiers/on-key';
import optional from 'ember-composable-helpers/helpers/optional';
import style from 'ember-style-modifier/modifiers/style';
import preventDefault from 'ember-event-helpers/helpers/prevent-default';
import stopPropagation from 'ember-event-helpers/helpers/stop-propagation';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiModalSignature {
  Element: HTMLDivElement;
  Args: {
    onClose?: () => void;
    maxWidth?: boolean | string;
    clickOutsideToClose?: boolean;
    isFocusTrapActive?: boolean;
    shouldSelfFocus?: boolean;
    isFocusTrapPaused?: boolean;
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
        {{focusTrapModifier
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
