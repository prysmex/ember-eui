import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiCodeBlockControlsStyles } from '../../utils/eui/styles.generated.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiCopy from '../eui-copy.gts';
import EuiDelayRender from '../eui-delay-render.gts';

import type EuiI18n from '../../services/eui-i18n.ts';

/** @private The copy and full screen buttons of EuiCodeBlock. */
interface EuiCodeBlockControlsSignature {
  Args: {
    /** Shows the copy button (`@isCopyable` and there is text to copy). */
    showCopyButton: boolean;
    /** Shows the full screen button (`@overflowHeight` is set). */
    showFullScreenButton: boolean;
    /** Whether the code is shown full screen (switches the button icon). */
    isFullScreen: boolean;
    /** Toggles the full screen view. */
    toggleFullScreen: () => void;
    /** The code to copy. */
    textToCopy: string;
    /** `aria-label` of the copy button. Defaults to `'Copy'` (i18n token `euiCodeBlockCopy.copy`). */
    copyAriaLabel?: string;
    /** Offsets the controls by the code block's padding. Defaults to `'l'`. */
    paddingSize?: 'none' | 's' | 'm' | 'l';
  };
}

type OffsetKey = 'none' | 's' | 'm' | 'l';

export default class EuiCodeBlockControls extends Component<EuiCodeBlockControlsSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiCodeBlockControlsStyles);
    const offset = (this.args.paddingSize ?? 'l') as OffsetKey;
    return `euiCodeBlock__controls ${euiClass(
      context,
      styles.euiCodeBlock__controls,
      styles.offset[offset]
    )}`;
  }

  get copyAriaLabel() {
    return (
      this.args.copyAriaLabel ??
      this.euiI18n.lookupToken('euiCodeBlockCopy.copy', 'Copy')
    );
  }

  get fullScreenAriaLabel() {
    return this.args.isFullScreen
      ? this.euiI18n.lookupToken(
          'euiCodeBlockFullScreen.fullscreenCollapse',
          'Collapse'
        )
      : this.euiI18n.lookupToken(
          'euiCodeBlockFullScreen.fullscreenExpand',
          'Expand'
        );
  }

  get copiedMessage() {
    return this.euiI18n.lookupToken('euiCopy.copied', 'Copied');
  }

  <template>
    {{#if (or @showCopyButton @showFullScreenButton)}}
      <div class={{this.classes}}>
        {{#if @showFullScreenButton}}
          {{#if @isFullScreen}}
            {{! Upstream delays the "Collapse" button so screen readers don't announce it before the dialog }}
            <EuiDelayRender @delay={{10}}>
              <EuiButtonIcon
                class="euiCodeBlock__fullScreenButton"
                @iconType="fullScreenExit"
                @color="text"
                aria-label={{this.fullScreenAriaLabel}}
                {{on "click" @toggleFullScreen}}
              />
            </EuiDelayRender>
          {{else}}
            <EuiButtonIcon
              class="euiCodeBlock__fullScreenButton"
              @iconType="fullScreen"
              @color="text"
              aria-label={{this.fullScreenAriaLabel}}
              {{on "click" @toggleFullScreen}}
            />
          {{/if}}
        {{/if}}

        {{#if @showCopyButton}}
          <div class="euiCodeBlock__copyButton">
            <EuiCopy
              @textToCopy={{@textToCopy}}
              @afterMessage={{this.copiedMessage}}
              as |copy|
            >
              <EuiButtonIcon
                {{on "click" copy}}
                @iconType="copy"
                @color="text"
                aria-label={{this.copyAriaLabel}}
                data-test-subj="euiCodeBlockCopy"
              />
            </EuiCopy>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
