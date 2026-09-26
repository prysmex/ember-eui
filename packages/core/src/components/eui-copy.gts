import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

import { copyToClipboard } from "../utils/copy-to-clipboard.ts";
import EuiToolTip from "./eui-tool-tip.gts";

import type { EuiToolTipSignature } from "./eui-tool-tip";

type EuiCopyArgs = {
  /**
   * Text that will be copied to clipboard when copy function is executed.
   */
  textToCopy: string;
  /**
   * Tooltip message displayed before copy function is called, e.g.
   * "Click to copy". No tooltip without it.
   */
  beforeMessage?: string;
  /**
   * Tooltip message displayed after copy function is called that lets the user know that
   * 'textToCopy' has been copied to the clipboard, e.g. "Copied".
   */
  afterMessage?: string;

  /**
   * @deprecated Has no effect: the tooltip is anchored to the block's
   * content.
   */
  anchor?: HTMLElement;
};

export interface EuiCopySignature {
  Element: EuiToolTipSignature['Element'];
  Args: EuiCopyArgs;
  Blocks: {
    /**
     * The element triggering the copy; call the yielded function from it:
     * `as |copy|` → `<EuiButton {{on "click" copy}}>Copy</EuiButton>`.
     */
    default: [() => void];
  };
}

export default class EuiCopyComponent extends Component<EuiCopySignature> {
  @tracked isCopied = false;

  get tooltipText() {
    return this.isCopied ? this.args.afterMessage : this.args.beforeMessage;
  }

  @action
  copy() {
    if (copyToClipboard(this.args.textToCopy)) {
      this.isCopied = true;
    }
  }

  @action
  resetTooltipText(): void {
    this.isCopied = false;
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
