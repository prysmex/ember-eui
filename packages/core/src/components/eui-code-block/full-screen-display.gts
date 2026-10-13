import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { focusTrap } from 'ember-focus-trap';
import { focusTrapFactory } from '../../-private/focus-trap-registry.ts';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiCodeBlockStyles } from '../../utils/eui/styles.generated.ts';
import EuiOverlayMask from '../eui-overlay-mask.gts';

import type EuiI18n from '../../services/eui-i18n.ts';

/**
 * @private EuiCodeBlock's full screen view: a modal dialog in an overlay
 * mask, forced to the large font (upstream `EuiCodeBlockFullScreenWrapper`).
 */
export interface FullScreenDisplaySignature {
  Element: HTMLDivElement;
  Args: {
    /** Keydown handler of the dialog (closes it on Escape). */
    onKeyDown?: (event: KeyboardEvent) => void;
  };
  Blocks: {
    default: [];
  };
}

const noop = () => {};

export default class FullScreenDisplay extends Component<FullScreenDisplaySignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiCodeBlockStyles);
    return `euiCodeBlockFullScreen ${euiClass(
      context,
      styles.euiCodeBlock,
      styles.l,
      styles.isFullScreen
    )}`;
  }

  get ariaLabel() {
    return this.euiI18n.lookupToken(
      'euiCodeBlockFullScreen.ariaLabel',
      'Expanded code block'
    );
  }

  get onKeyDown() {
    return this.args.onKeyDown ?? noop;
  }

  <template>
    <EuiOverlayMask>
      <div
        class={{this.classes}}
        role="dialog"
        aria-modal="true"
        aria-label={{this.ariaLabel}}
        {{on "keydown" this.onKeyDown}}
        {{focusTrap
          _createFocusTrap=focusTrapFactory
          isActive=true
          focusTrapOptions=(hash
            clickOutsideDeactivates=true escapeDeactivates=false
          )
        }}
        ...attributes
      >
        {{yield}}
      </div>
    </EuiOverlayMask>
  </template>
}
