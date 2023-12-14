import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { throttle } from '@ember/runloop';

import { modifier } from 'ember-modifier';
import { and, not, or } from 'ember-truth-helpers';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import argOrDefault from '../helpers/arg-or-default';
import { isWithinMinBreakpoint } from '../utils/breakpoint';
import EuiFlyout from './eui-flyout.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint';
import type { EuiFlyoutSignature } from './eui-flyout.gts';
import type { ModifierLike } from '@glint/template';

export type EuiCollapsibleNavArgs = {
  id?: string;
  /**
   * ReactNode to render as this component's content
   */
  children?: Component;
  /**
   * Shows the navigation flyout
   */
  isOpen?: boolean;
  /**
   * Keeps navigation flyout visible and push `<body>` content via padding
   */
  isDocked?: boolean;
  /**
   * Named breakpoint or pixel value for customizing the minimum window width to enable docking
   */
  dockedBreakpoint?: EuiBreakpointSize | number;
  /**
   * Keeps the display of toggle button when in docked state
   */
  showButtonIfDocked?: boolean;

  as: string;

  size?: EuiFlyoutSignature['Args']['size'];

  side?: 'left' | 'right';

  role?: null | string;

  ownFocus?: boolean;

  outsideClickCloses?: boolean;

  closeButtonPosition?: 'outside' | 'inside';

  paddingSize?: string;

  onClose: EuiFlyoutSignature['Args']['onClose'];
};

const triggerHandlersModifier = modifier(
  (
    element: Element,
    _pos,
    { flyoutID, isOpen }: { flyoutID: string; isOpen: boolean }
  ) => {
    element.setAttribute('aria-controls', flyoutID);
    element.setAttribute('aria-expanded', isOpen ? 'true' : '');
    element.setAttribute('aria-pressed', isOpen ? 'true' : '');

    const fn = (e: Event) => {
      e.stopImmediatePropagation();
    };

    element.addEventListener('touchend', fn);
    element.addEventListener('mouseup', fn, true);

    return () => {
      element.removeEventListener('touchend', fn);
      element.removeEventListener('mouseup', fn, true);
    };
  }
);

const onWindowResizeModifier = modifier(
  (
    _ele: HTMLElement,
    _pos,
    {
      isDocked = false,
      functionToCallOnWindowResize
    }: { isDocked?: boolean; functionToCallOnWindowResize: () => void }
  ) => {
    if (isDocked) {
      window.addEventListener('resize', functionToCallOnWindowResize);
    }

    return () => {
      if (isDocked) {
        window.removeEventListener('resize', functionToCallOnWindowResize);
      }
    };
  }
);

export interface EuiCollapsibleNavSignature {
  Element: EuiFlyoutSignature['Element'];
  Args: EuiCollapsibleNavArgs;
  Blocks: {
    default: [];
    button: [
      ModifierLike<{
        Element: Element;
      }>
    ];
    content: [];
  };
}
export default class EuiCollapsibleNavComponent extends Component<EuiCollapsibleNavSignature> {
  @tracked windowIsLargeEnoughToPush = isWithinMinBreakpoint(
    typeof window === 'undefined' ? -Infinity : window.innerWidth,
    this.dockedBreakpoint
  );

  get isDocked() {
    return this.args.isDocked ?? false;
  }

  get navIsDocked() {
    return this.isDocked && this.windowIsLargeEnoughToPush;
  }

  get dockedBreakpoint() {
    return this.args.dockedBreakpoint ?? 'l';
  }

  get showButtonIfDocked() {
    return this.args.showButtonIfDocked ?? false;
  }

  get as() {
    return this.args.as ?? 'nav';
  }

  get size() {
    if (this.args.size && typeof this.args.size !== 'string') {
      return `${this.args.size}px`;
    }

    return this.args.size ?? '320px';
  }

  get side() {
    return this.args.side ?? 'left';
  }

  get role() {
    return this.args.role ?? null;
  }

  get ownFocus() {
    return this.args.ownFocus ?? true;
  }

  get outsideClickCloses() {
    return this.args.outsideClickCloses ?? true;
  }

  get closeButtonPosition() {
    return this.args.closeButtonPosition ?? 'outside';
  }

  get paddingSize() {
    return this.args.paddingSize ?? 'none';
  }

  @action
  functionToCallOnWindowResize() {
    throttle(() => {
      if (isWithinMinBreakpoint(window.innerWidth, this.dockedBreakpoint)) {
        this.windowIsLargeEnoughToPush = true;
      } else {
        this.windowIsLargeEnoughToPush = false;
      }
    }, 50);
  }

  <template>
    <span
      {{onWindowResizeModifier
        isDocked=this.isDocked
        functionToCallOnWindowResize=this.functionToCallOnWindowResize
      }}
    ></span>
    {{#let (argOrDefault @id (uniqueId)) as |flyoutID|}}

      {{#if (not (and this.navIsDocked (not this.showButtonIfDocked)))}}
        {{yield
          (modifier triggerHandlersModifier isOpen=@isOpen flyoutID=flyoutID)
          to="button"
        }}
      {{/if}}

      {{#if (or @isOpen this.navIsDocked)}}
        <EuiFlyout
          id={{flyoutID}}
          class="euiCollapsibleNav"
          @as={{this.as}}
          @size={{this.size}}
          @side={{this.side}}
          @role={{this.role}}
          @ownFocus={{this.ownFocus}}
          @outsideClickCloses={{this.outsideClickCloses}}
          @closeButtonPosition={{this.closeButtonPosition}}
          @paddingSize={{this.paddingSize}}
          @type={{if this.navIsDocked "push" "overlay"}}
          @hideCloseButton={{this.navIsDocked}}
          @pushMinBreakpoint={{this.dockedBreakpoint}}
          @onClose={{@onClose}}
          ...attributes
        >
          {{yield to="content"}}
        </EuiFlyout>
      {{/if}}
    {{/let}}
  </template>
}
