import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { euiPopoverPanelPadding } from '../-private/eui-popover-panel-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiPaddingSize,
  euiPopoverFooterStyles
} from '../utils/eui/styles.generated.ts';

import type { EuiPopoverPanelPaddingSize } from '../-private/eui-popover-panel-context.ts';

/** The footer of an EuiPopover (separated by a border). */
export interface EuiPopoverFooterSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to the containing
     * EuiPopover's `@panelPaddingSize`.
     */
    paddingSize?: EuiPopoverPanelPaddingSize;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** E.g. a full width button. */
    default: [];
  };
}

export default class EuiPopoverFooter extends Component<EuiPopoverFooterSignature> {
  /**
   * Upstream: small text, top border and bottom radius; negative
   * margins cover the panel's padding.
   */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPopoverFooterStyles);
    const panelPadding = euiPopoverPanelPadding(this);
    const padding = euiPaddingSize(
      context.upstream,
      this.args.paddingSize ?? panelPadding
    );

    return `euiPopoverFooter ${euiClass(
      context,
      styles.euiPopoverFooter,
      styles.panelPaddingSizes[panelPadding],
      padding && { padding },
      this.args.css
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{yield}}
    </div>
  </template>
}
