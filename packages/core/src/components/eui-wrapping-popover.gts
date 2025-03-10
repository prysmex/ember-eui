import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import EuiPopover from './eui-popover.gts';
import EuiPortal from './eui-portal.gts';

import type { EuiPopoverSignature } from './eui-popover.gts';

export interface EuiWrappingPopoverSignature {
  Element: EuiPopoverSignature['Element'];
  Args: EuiPopoverSignature['Args'] & {
    button?: HTMLElement;
    onWrappingDestroy: () => void;
  };
  Blocks: {
    default: [];
  };
}

export default class EuiWrappingPopover extends Component<EuiWrappingPopoverSignature> {
  private portal: HTMLElement | null = null;
  private anchor: HTMLElement | null = null;

  setAnchorRef = modifier((element: HTMLElement) => {
    this.anchor = element;
    this.anchor.insertAdjacentElement('beforebegin', this.args.button!);
  });

  setPortalRef = (element: HTMLElement) => {
    this.portal = element;
  };

  get insert(): { sibling: HTMLElement; position: 'after' } | undefined {
    if (this.args.button) {
      return {
        sibling: this.args.button,
        position: 'after'
      };
    }

    return;
  }

  willDestroy() {
    super.willDestroy();

    if (this.args.button && this.args.button.parentNode) {
      if (this.portal) {
        this.portal.insertAdjacentElement('beforebegin', this.args.button);
      }
    }
    this.args.onWrappingDestroy();
  }

  <template>
    <EuiPortal @portalRef={{this.setPortalRef}} @insert={{this.insert}}>
      <EuiPopover
        @closePopover={{@closePopover}}
        @isOpen={{@isOpen}}
        @anchorClassName={{@anchorClassName}}
        @anchorPosition={{@anchorPosition}}
        @attachToAnchor={{@attachToAnchor}}
        @container={{@container}}
        @display={{@display}}
        @hasArrow={{@hasArrow}}
        @initialFocus={{@initialFocus}}
        @ownFocus={{@ownFocus}}
        @panelClassName={{@panelClassName}}
        @panelPaddingSize={{@panelPaddingSize}}
        @panelStyle={{@panelStyle}}
        @panelRef={{@panelRef}}
        @popoverRef={{@popoverRef}}
        ...attributes
      >
        <:button>
          <div {{this.setAnchorRef}} class="euiWrappingPopover__anchor" />
        </:button>

        <:content>
          {{yield}}
        </:content>
      </EuiPopover>
    </EuiPortal>
  </template>
}
