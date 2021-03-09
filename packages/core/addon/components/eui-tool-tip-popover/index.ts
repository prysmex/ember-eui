import Component from '@glimmer/component';
import { action } from '@ember/object';
import { CommonArgs } from '../common';

type EuiTooltipPopoverArgs = CommonArgs &
  Omit<HTMLDivElement, 'title'> & {
    positionToolTip: () => void;
    title?: Component;
    popoverRef?: (ref: HTMLDivElement) => void;
  };

export default class EuiTooltipPopover extends Component<EuiTooltipPopoverArgs> {
  popover: HTMLDivElement | undefined;

  constructor(owner: unknown, args: EuiTooltipPopoverArgs) {
    super(owner, args);
    document.body.classList.add('euiBody-hasPortalContent');
    window.addEventListener('resize', this.updateDimensions);
  }

  willDestroy(): void {
    super.willDestroy();
    document.body.classList.remove('euiBody-hasPortalContent');
    window.removeEventListener('resize', this.updateDimensions);
  }

  @action
  setPopoverRef(popover: HTMLDivElement): void {
    this.popover = popover;
    if (this.args.popoverRef) {
      this.args.popoverRef(popover);
    }
  }

  @action
  updateDimensions(): void {
    requestAnimationFrame(() => {
      // Because of this delay, sometimes `positionToolTip` becomes unavailable.
      if (this.popover) {
        this.args.positionToolTip();
      }
    });
  }
}
