import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { euiPopoverPanelPadding } from '../-private/eui-popover-panel-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiPaddingSize,
  euiPopoverTitleStyles
} from '../utils/eui/styles.generated.ts';

import type { EuiPopoverPanelPaddingSize } from '../-private/eui-popover-panel-context.ts';

/** The title of an EuiPopover (separated by a border). */
export interface EuiPopoverTitleSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to the containing
     * EuiPopover's `@panelPaddingSize`.
     */
    paddingSize?: EuiPopoverPanelPaddingSize;
  };
  Blocks: {
    /** The title text. */
    default: [];
  };
}

export default class EuiPopoverTitle extends Component<EuiPopoverTitleSignature> {
  /**
   * Upstream: title type (xxs), bottom border and top radius; negative
   * margins cover the panel's padding.
   */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPopoverTitleStyles);
    const panelPadding = euiPopoverPanelPadding(this);
    const padding = euiPaddingSize(
      context.upstream,
      this.args.paddingSize ?? panelPadding
    );

    return `euiPopoverTitle ${euiClass(
      context,
      styles.euiPopoverTitle,
      styles.panelPaddingSizes[panelPadding],
      padding && { padding }
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{yield}}
    </div>
  </template>
}
