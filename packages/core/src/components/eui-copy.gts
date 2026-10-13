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

  /**
   * EuiToolTip args for the tooltip (upstream `tooltipProps`), e.g.
   * `(hash position="bottom" anchorProps=(hash data-test-subj="copy"))`.
   * Every EuiToolTip arg except `content` and `onMouseOut` is supported;
   * `onBlur` is called before the copied message resets.
   */
  tooltipProps?: Partial<
    Omit<EuiToolTipSignature['Args'], 'content' | 'onMouseOut'>
  >;
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

  /** Upstream: blurring the anchor resets the copied message. */
  @action
  onBlur(): void {
    this.args.tooltipProps?.onBlur?.();
    if (this.isCopied) this.resetTooltipText();
  }

  /** Upstream: the copied message is not announced as a description. */
  get disableScreenReaderOutput(): boolean {
    return this.isCopied || !!this.args.tooltipProps?.disableScreenReaderOutput;
  }

  <template>
    <EuiToolTip
      @content={{this.tooltipText}}
      @onMouseOut={{this.resetTooltipText}}
      @onBlur={{this.onBlur}}
      @disableScreenReaderOutput={{this.disableScreenReaderOutput}}
      @title={{@tooltipProps.title}}
      @position={{@tooltipProps.position}}
      @delay={{@tooltipProps.delay}}
      @offset={{@tooltipProps.offset}}
      @display={{@tooltipProps.display}}
      @id={{@tooltipProps.id}}
      @className={{@tooltipProps.className}}
      @anchorClassName={{@tooltipProps.anchorClassName}}
      @anchorCss={{@tooltipProps.anchorCss}}
      @anchorStyle={{@tooltipProps.anchorStyle}}
      @anchorProps={{@tooltipProps.anchorProps}}
      @attachTo={{@tooltipProps.attachTo}}
      @repositionOnScroll={{@tooltipProps.repositionOnScroll}}
      @isShown={{@tooltipProps.isShown}}
      @onFocus={{@tooltipProps.onFocus}}
      @hasTitle={{@tooltipProps.hasTitle}}
      @css={{@tooltipProps.css}}
      ...attributes
    >
      <:anchor>
        {{yield this.copy}}
      </:anchor>
    </EuiToolTip>
  </template>
}
