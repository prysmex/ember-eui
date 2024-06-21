import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import { hash } from '@ember/helper';
import { action } from '@ember/object';

import { focusTrap } from 'ember-focus-trap';
import onKey from 'ember-keyboard/modifiers/on-key';
import { not } from 'ember-truth-helpers';
import { tabbable } from 'tabbable';

import randomId from '../-private/random-id.ts';
import { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import { cascadingMenuKeys } from '../utils/accesibility/index.ts';
import EuiPopover from './eui-popover.gts';

import type { EuiPopoverArgs } from './eui-popover';

export interface EuiInputPopoverArgs
  extends Omit<EuiPopoverArgs, 'button' | 'buttonRef'> {
  disableFocusTrap?: boolean;
  fullWidth?: boolean;
  input?: EuiPopoverArgs['button'];
  inputRef?: EuiPopoverArgs['buttonRef'];
  onPanelResize?: (width?: number) => void;
}

export interface EuiInputPopoverSignature {
  Element: HTMLElement;
  Args: EuiInputPopoverArgs;
  Blocks: {
    default: [
      {
        closePopover: () => void;
        isOpen: boolean;
      },
      {
        input: HTMLElement;
        content: HTMLElement;
      }
    ];
    input: [];
    content: [];
  };
}

export default class EuiInputPopoverComponent extends Component<EuiInputPopoverSignature> {
  // Defaults
  @argOrDefaultDecorator('downLeft') anchorPosition!: EuiPopoverArgs['anchorPosition'];
  @argOrDefaultDecorator(true) attachToAnchor!: boolean;
  @argOrDefaultDecorator('block') display!: EuiPopoverArgs['display'];
  @argOrDefaultDecorator('s') panelPaddingSize!: EuiPopoverArgs['panelPaddingSize'];
  @argOrDefaultDecorator(false) fullWidth!: boolean;
  @argOrDefaultDecorator(false) disableFocusTrap!: boolean;

  //State
  @tracked panel: HTMLElement | null = null;
  @tracked input: HTMLElement | null = null;
  @tracked inputWidth!: number;
  ///

  @action
  didInsertPanel(panel: HTMLElement | null): void {
    this.panel = panel;
    this.setPanelWidth();
  }

  @action
  didInsertInput(input: HTMLElement): void {
    this.input = input;
    this.onResize();
  }

  @action
  setPanelWidth(width?: number): void {
    const { panel, inputWidth } = this;
    const newWidth = width || inputWidth;

    if (panel && !!newWidth) {
      panel.style.width = `${newWidth}px`;
      this.args.onPanelResize?.(newWidth);
    }
  }

  @action
  onResize(): void {
    const { input } = this;

    if (input) {
      const width = input.getBoundingClientRect().width;

      this.inputWidth = width;
      this.setPanelWidth(width);
    }
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    const { panel } = this;

    if (panel && event.key === cascadingMenuKeys.TAB) {
      const tabbableItems = tabbable(panel).filter(
        (el: HTMLElement | SVGElement) => {
          return (
            Array.from(el.attributes)
              .map((el) => el.name)
              .indexOf('data-focus-guard') < 0
          );
        }
      );

      if (
        this.args.disableFocusTrap ||
        (tabbableItems.length &&
          tabbableItems[tabbableItems.length - 1] === document.activeElement)
      ) {
        this.args.closePopover?.();
      }
    }
  }

  <template>
    {{#let (randomId) as |id|}}
      <EuiPopover
        class="euiInputPopover
          {{if this.fullWidth 'euiInputPopover--fullWidth'}}"
        @ownFocus={{false}}
        @buttonRef={{this.didInsertInput}}
        @panelRef={{this.didInsertPanel}}
        @anchorPosition={{this.anchorPosition}}
        @panelPaddingSize={{this.panelPaddingSize}}
        @attachToAnchor={{this.attachToAnchor}}
        @display={{this.display}}
        @closePopover={{@closePopover}}
        @isOpen={{@isOpen}}
        ...attributes
      >
        <:button>
          <div {{resizeObserver onResize=this.onResize}}>
            {{yield to="input"}}
          </div>
        </:button>
        <:content>
          <div
            id={{id}}
            {{onKey "_all" this.onKeyDown}}
            {{focusTrap
              isActive=(not this.disableFocusTrap)
              focusTrapOptions=(hash
                clickOutsideDeactivates=true
                returnFocusOnDeactivate=false
                fallbackFocus=(concat "#" id)
              )
            }}
          >
            {{yield to="content"}}
          </div>
        </:content>
      </EuiPopover>
    {{/let}}
  </template>
}
