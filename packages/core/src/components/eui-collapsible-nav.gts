import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { throttle } from '@ember/runloop';

import { modifier as modBuilder } from 'ember-modifier';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import { isWithinMinBreakpoint } from '../utils/breakpoint.ts';
import EuiFlyout from './eui-flyout.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';
import type { EuiFlyoutSignature } from './eui-flyout';
import type { ModifierLike } from '@glint/template';

export type EuiCollapsibleNavArgs = {
  /** Id of the nav flyout, which the button controls. Defaults to a random id. */
  id?: string;
  /**
   * @deprecated Has no effect, use the `<:content>` block.
   */
  children?: Component;
  /**
   * Shows the navigation flyout. Toggle it from the `<:button>` block's
   * button and set it to `false` in `@onClose`.
   */
  isOpen?: boolean;
  /**
   * Keeps navigation flyout visible and push `<body>` content via padding,
   * on windows at least `@dockedBreakpoint` wide. Defaults to `false`.
   */
  isDocked?: boolean;
  /**
   * Named breakpoint (`'xs'`, `'s'`, `'m'`, `'l'`, `'xl'`) or pixel value:
   * the minimum window width for docking. Defaults to `'l'`.
   */
  dockedBreakpoint?: EuiBreakpointSize | number;
  /**
   * Keeps the display of toggle button when in docked state.
   * Defaults to `false`.
   */
  showButtonIfDocked?: boolean;
  /** Tag of the flyout. Defaults to `'nav'`. */
  as: string;
  /** Width of the nav, a number in px or any CSS width. Defaults to `320px`. */
  size?: EuiFlyoutSignature['Args']['size'];
  /** Side of the window: `'left'` or `'right'`. Defaults to `'left'`. */
  side?: 'left' | 'right';
  /** `role` of the flyout. Defaults to none (the `<nav>` is a landmark). */
  role?: null | string;
  /** Traps focus in the open (not docked) nav. Defaults to `true`. */
  ownFocus?: boolean;
  /** Clicking outside the open nav calls `@onClose`. Defaults to `true`. */
  outsideClickCloses?: boolean;
  /**
   * Close button `'outside'` or `'inside'` the flyout (hidden while docked).
   * Defaults to `'outside'`.
   */
  closeButtonPosition?: 'outside' | 'inside';
  /** Padding inside the nav, any `EuiFlyout` padding size. Defaults to `'none'`. */
  paddingSize?: string;
  /** Called to close the nav (close button, Escape, outside click). */
  onClose: EuiFlyoutSignature['Args']['onClose'];
};

const triggerHandlersModifier = modBuilder(
  (
    element: Element,
    _pos,
    { flyoutID, isOpen }: { flyoutID: string; isOpen: boolean }
  ) => {
    element.setAttribute('aria-controls', flyoutID);
    element.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    element.setAttribute('aria-pressed', isOpen ? 'true' : 'false');

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

const onWindowResizeModifier = modBuilder(
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
    /** Unused, use `<:button>` and `<:content>`. */
    default: [];
    /**
     * The toggle button, usually an `EuiHeaderSectionItemButton`. Apply the
     * yielded modifier to it for the `aria-controls` / `aria-expanded`
     * attributes: `<:button as |navButton|><EuiButton {{navButton}} …>`.
     * Hidden while docked unless `@showButtonIfDocked`.
     */
    button: [
      ModifierLike<{
        Element: Element;
      }>
    ];
    /** The navigation, e.g. `EuiCollapsibleNavGroup`s and `EuiListGroup`s. */
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
    {{#let (argOrDefault @id (randomId)) as |flyoutID|}}

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
