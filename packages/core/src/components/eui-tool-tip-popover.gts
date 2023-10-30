import Component from '@glimmer/component';
import { action } from '@ember/object';
import { CommonArgs } from '../common';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import willDestroy from '@ember/render-modifiers/modifiers/will-destroy';
import { fn } from '@ember/helper';

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
    window.addEventListener('scroll', this.updateDimensions, true);
  }

  willDestroy(): void {
    super.willDestroy();
    document.body.classList.remove('euiBody-hasPortalContent');
    window.removeEventListener('resize', this.updateDimensions);
    window.removeEventListener('scroll', this.updateDimensions, true);
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

  <template>
    {{! @glint-nocheck: not typesafe yet }}
    <div
      class="euiToolTipPopover"
      ...attributes
      {{didInsert this.setPopoverRef}}
      {{willDestroy (fn this.setPopoverRef null)}}
    >
      {{#if @hasTitle}}
        <div class="euiToolTip__title">
          {{yield to="title"}}
        </div>
      {{/if}}
      {{yield to="content"}}
    </div>
  </template>
}
