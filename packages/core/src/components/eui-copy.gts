import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { copyToClipboard } from "../utils/copy-to-clipboard";

import EuiToolTip from "./eui-tool-tip.gts";
import type { EuiToolTipSignature } from "./eui-tool-tip.gts";

type EuiCopyArgs = {
  /**
   * Text that will be copied to clipboard when copy function is executed.
   */
  textToCopy: string;
  /**
   * Tooltip message displayed before copy function is called.
   */
  beforeMessage?: string;
  /**
   * Tooltip message displayed after copy function is called that lets the user know that
   * 'textToCopy' has been copied to the clipboard.
   */
  afterMessage?: string;

  /**
   * The element that will be used as the anchor for the tooltip.
   * Defaults to the child element of EuiCopy.
   */
  anchor?: HTMLElement;
};

export interface EuiCopySignature {
  Element: EuiToolTipSignature["Element"];
  Args: EuiCopyArgs;
  Blocks: {
    default: [() => void];
  };
}

export default class EuiCopyComponent extends Component<EuiCopySignature> {
  @tracked tooltipText = this.args.beforeMessage;

  @action
  copy() {
    const isCopied = copyToClipboard(this.args.textToCopy);
    if (isCopied) {
      this.tooltipText = this.args.afterMessage;
    }
  }

  @action
  resetTooltipText(): void {
    this.tooltipText = this.args.beforeMessage;
  }

  <template>
    <EuiToolTip
      @content={{this.tooltipText}}
      @onMouseOut={{this.resetTooltipText}}
      ...attributes
    >
      <:anchor>
        {{yield this.copy}}
      </:anchor>
    </EuiToolTip>
  </template>
}
