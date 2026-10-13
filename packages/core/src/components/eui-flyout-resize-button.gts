import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiFlyoutResizeButtonStyles,
  euiResizableButtonStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

import type EuiI18n from '../services/eui-i18n.ts';

/**
 * @private The horizontal resize handle `EuiFlyoutResizable` renders at the
 * flyout's inner edge: upstream's `EuiFlyoutResizeButton`, a standalone
 * `EuiResizableButton` (border indicator) positioned on the flyout. Drag it
 * or focus it and use the arrow keys; the flyout wires the events.
 */
export interface EuiFlyoutResizeButtonSignature {
  Element: HTMLButtonElement;
  Args: {
    /** The flyout's type. */
    type: 'push' | 'overlay';
    /** The flyout's side. */
    side: 'left' | 'right';
    /** Whether the flyout has an overlay mask. */
    ownFocus: boolean;
  };
}

/** React's global `button` reset, scoped (as `EuiResizableButton`). */
const BUTTON_RESET = {
  boxSizing: 'border-box',
  appearance: 'none',
  margin: 0,
  padding: 0,
  border: 'none',
  borderRadius: 0,
  background: 'none',
  color: 'inherit',
  font: 'inherit'
} as const;

export default class EuiFlyoutResizeButton extends Component<EuiFlyoutResizeButtonSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const button = useEuiBorealisStyles(context, euiResizableButtonStyles);
    const flyout = useEuiBorealisStyles(context, euiFlyoutResizeButtonStyles);
    const { type, side } = this.args;
    const hasOverlay = this.args.ownFocus && type === 'overlay';

    // `EuiResizableButton`'s own styles, then the flyout's (like upstream,
    // where the flyout's `css` is composed after the button's).
    return `euiResizableButton ${euiClass(
      context,
      BUTTON_RESET,
      button.euiResizableButton,
      button.border,
      button.borderDirection.horizontal,
      button.horizontal,
      button.accountForScrollbars.horizontal.none,
      flyout.root,
      flyout[type][side],
      !hasOverlay && flyout.noOverlay.root,
      !hasOverlay && flyout.noOverlay[side]
    )}`;
  }

  get label(): string {
    return this.euiI18n.lookupToken(
      'euiResizableButton.horizontalResizerAriaLabel',
      'Press the left or right arrow keys to adjust panels size'
    );
  }

  <template>
    <button
      type="button"
      class={{this.classes}}
      aria-label={{this.label}}
      data-test-subj="euiResizableButton"
      ...attributes
    ></button>
  </template>
}
