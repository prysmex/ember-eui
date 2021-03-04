import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { cascadingMenuKeys } from '../../utils/accesibility';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { tabbable } from 'tabbable';
import { EuiPopoverArgs } from '../eui-popover';

export interface EuiInputPopoverArgs extends Omit<EuiPopoverArgs, 'button' | 'buttonRef'> {
  disableFocusTrap?: boolean;
  fullWidth?: boolean;
  input: EuiPopoverArgs['button'];
  inputRef?: EuiPopoverArgs['buttonRef'];
  onPanelResize?: (width?: number) => void;
}

export default class EuiInputPopoverComponent extends Component<EuiInputPopoverArgs> {
  // Defaults
  @argOrDefault('downLeft') anchorPosition!: string;
  @argOrDefault(true) attachToAnchor!: boolean;
  @argOrDefault('block') display!: string;
  @argOrDefault('s') panelPaddingSize!: string;
  @argOrDefault(false) fullWidth!: boolean;
  @argOrDefault(false) disableFocusTrap!: boolean;

  //State
  @tracked panel: HTMLElement | null = null;
  @tracked input: HTMLElement | null = null;
  @tracked inputWidth!: number;
  ///

  @action
  didInsertPanel(panel: HTMLElement) {
    this.panel = panel;
    this.setPanelWidth();
  }

  @action
  didInsertInput(input: HTMLElement) {
    this.input = input;
    this.onResize();
  }

  @action
  setPanelWidth(width?: number) {
    let { panel, inputWidth } = this;
    if (panel && (!!inputWidth || !!width)) {
      const newWidth = !!width ? width : inputWidth;
      panel.style.width = `${newWidth}px`;
      this.args.onPanelResize?.(newWidth);
    }
  }

  @action
  onResize() {
    let { input } = this;
    if (input) {
      const width = input.getBoundingClientRect().width;
      this.inputWidth = width;
      this.setPanelWidth(width);
    }
  }

  @action
  onKeyDown(event: KeyboardEvent) {
    let { panel } = this;
    if (panel && event.key === cascadingMenuKeys.TAB) {
      const tabbableItems = tabbable(panel).filter((el: HTMLElement) => {
        return (
          Array.from(el.attributes)
            .map((el) => el.name)
            .indexOf('data-focus-guard') < 0
        );
      });
      if (
        this.args.disableFocusTrap ||
        (tabbableItems.length && tabbableItems[tabbableItems.length - 1] === document.activeElement)
      ) {
        this.args.closePopover?.();
      }
    }
  }
}
