import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import willDestroy from '@ember/render-modifiers/modifiers/will-destroy';
import type Owner from '@ember/owner';

import type { CommonArgs } from './common.ts';

type EuiTooltipPopoverArgs = CommonArgs & {
    positionToolTip: () => void;
    title?: Component;
    popoverRef?: (ref: HTMLDivElement | null) => void;
    hasTitle?: boolean;
  };

export interface EuiTooltipPopoverSignature {
  Element: HTMLDivElement;
  Args: EuiTooltipPopoverArgs;
  Blocks: {
    default: [];
    title: [];
    content: [];
  };
}

export default class EuiTooltipPopover extends Component<EuiTooltipPopoverSignature> {
  popover: HTMLDivElement | null = null;

  constructor(owner: Owner, args: EuiTooltipPopoverArgs) {
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
  setPopoverRef(popover: HTMLDivElement | null): void {
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
    <div
      class="euiToolTipPopover"
      {{didInsert this.setPopoverRef}}
      {{willDestroy (fn this.setPopoverRef null)}}
      ...attributes
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
