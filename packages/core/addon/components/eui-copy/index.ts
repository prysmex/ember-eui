import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { copyToClipboard } from '../../utils/copy-to-clipboard';

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
};

export default class EuiCopyComponent extends Component<EuiCopyArgs> {
  @tracked tooltipText = this.args.beforeMessage;

  @action
  copy(): void {
    const isCopied = copyToClipboard(this.args.textToCopy);
    if (isCopied) {
      this.tooltipText = this.args.afterMessage;
    }
  }

  @action
  resetTooltipText(): void {
    this.tooltipText = this.args.beforeMessage;
  }
}
