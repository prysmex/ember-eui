import { on } from '@ember/modifier';

import { or } from 'ember-truth-helpers';

import EuiButtonIcon from '../eui-button-icon.gts';
import EuiCopy from '../eui-copy.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The copy and full screen buttons of EuiCodeBlock. */
interface EuiCodeBlockControlsSignature {
  Args: {
    /** Shows the copy button (`@isCopyable`). */
    showCopyButton: boolean;
    /** Shows the full screen button (code taller than `@overflowHeight`). */
    showFullScreenButton: boolean;
    /** Whether the code is shown full screen (switches the button icon). */
    isFullScreen: boolean;
    /** Toggles the full screen view. */
    toggleFullScreen: () => void;
    /** The code to copy. */
    textToCopy: string;
  };
}

const EuiCodeBlockControls: TemplateOnlyComponent<EuiCodeBlockControlsSignature> =
  <template>
    {{#if (or @showCopyButton @showFullScreenButton)}}
      <div class="euiCodeBlock__controls">
        {{#if @showFullScreenButton}}
          <EuiButtonIcon
            class="euiCodeBlock__fullScreenButton"
            @iconType={{if @isFullScreen "fullScreenExit" "fullScreen"}}
            @color="text"
            aria-label={{if @isFullScreen "Collapse" "Expand"}}
            {{on "click" @toggleFullScreen}}
          />
        {{/if}}

        {{#if @showCopyButton}}
          <div class="euiCodeBlock__copyButton">
            <EuiCopy
              @textToCopy={{@textToCopy}}
              @afterMessage="Copied"
              as |copy|
            >
              <EuiButtonIcon
                {{on "click" copy}}
                @iconType="copyClipboard"
                @color="text"
                aria-label="Copy"
              />
            </EuiCopy>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>;

export default EuiCodeBlockControls;
