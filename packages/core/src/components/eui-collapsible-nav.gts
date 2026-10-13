import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { throttle } from '@ember/runloop';

import { modifier as modBuilder } from 'ember-modifier';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import { isWithinMinBreakpoint } from '../utils/breakpoint.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiCollapsibleNavStyles } from '../utils/eui/styles.generated.ts';
import EuiFlyout from './eui-flyout.gts';

import type { EuiBreakpointSize, EuiBreakpoints } from '../utils/breakpoint.ts';
import type { EuiFlyoutArgs, EuiFlyoutSignature } from './eui-flyout';
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
  /**
   * Flyout session (EuiFlyout `@session`). Defaults to `'never'`, as
   * upstream: the nav stays out of managed flyout sessions.
   */
  session?: EuiFlyoutArgs['session'];
  /**
   * Focus trap options (EuiFlyout `@focusTrapProps`). The toggle button
   * is always added to `shards`, as upstream.
   */
  focusTrapProps?: EuiFlyoutArgs['focusTrapProps'];
} & Pick<
  EuiFlyoutArgs,
  | 'closeButtonProps'
  | 'container'
  | 'flyoutMenuDisplayMode'
  | 'flyoutMenuProps'
  | 'hasAnimation'
  | 'hasChildBackground'
  | 'historyKey'
  | 'includeFixedHeadersInFocusTrap'
  | 'includeSelectorInFocusTrap'
  | 'maskProps'
  | 'maxWidth'
  | 'minWidth'
  | 'onActive'
  | 'onResize'
  | 'pushAnimation'
  | 'resizable'
>;

const triggerHandlersModifier = modBuilder(
  (
    element: Element,
    _pos,
    {
      flyoutID,
      isOpen,
      register
    }: {
      flyoutID: string;
      isOpen: boolean;
      register?: (element: HTMLElement | null) => void;
    }
  ) => {
    register?.(element as HTMLElement);
    element.setAttribute('aria-controls', flyoutID);
    element.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    element.setAttribute('aria-pressed', isOpen ? 'true' : 'false');

    const fn = (e: Event) => {
      e.stopImmediatePropagation();
    };

    element.addEventListener('touchend', fn);
    element.addEventListener('mouseup', fn, true);

    return () => {
      register?.(null);
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
/**
 * Upstream `EuiCollapsibleNav` (the flyout-based nav, not
 * `EuiCollapsibleNavBeta`): an `EuiFlyout` with `euiCollapsibleNavStyles`
 * composed over it (`push` while docked, `overlay` with
 * `levels.navigation` z-index otherwise). Docking follows the nearest
 * theme's breakpoints, like upstream `useIsWithinMinBreakpoint`.
 */
export default class EuiCollapsibleNavComponent extends Component<EuiCollapsibleNavSignature> {
  @tracked windowWidth =
    typeof window === 'undefined' ? -Infinity : window.innerWidth;

  get windowIsLargeEnoughToPush(): boolean {
    return isWithinMinBreakpoint(
      this.windowWidth,
      this.dockedBreakpoint,
      this.breakpoints
    );
  }

  get breakpoints(): EuiBreakpoints {
    return getEuiThemeContext(this).upstream.euiTheme
      .breakpoint as EuiBreakpoints;
  }

  get flyoutType(): 'push' | 'overlay' {
    return this.navIsDocked ? 'push' : 'overlay';
  }

  /** Composed into EuiFlyout's own class through `@css`, as upstream. */
  @cached
  get flyoutCss(): EuiCss {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiCollapsibleNavStyles);
    return [styles.euiCollapsibleNav, styles[this.flyoutType]];
  }

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

  /** The toggle button, a focus trap shard (upstream `buttonRef`). */
  buttonElement: HTMLElement | null = null;

  registerButton = (element: HTMLElement | null): void => {
    this.buttonElement = element;
  };

  /** Read when the flyout's focus trap is created, after the button. */
  get focusTrapProps(): EuiFlyoutArgs['focusTrapProps'] {
    const own = this.args.focusTrapProps;
    const button = this.buttonElement;

    return {
      ...own,
      shards: [...(button ? [button] : []), ...(own?.shards ?? [])]
    };
  }

  get session(): EuiFlyoutArgs['session'] {
    return this.args.session ?? 'never';
  }

  @action
  functionToCallOnWindowResize() {
    throttle(this, this.measureWindow, 50);
  }

  measureWindow() {
    if (this.isDestroying || this.isDestroyed) return;
    this.windowWidth = window.innerWidth;
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
          (modifier
            triggerHandlersModifier
            isOpen=@isOpen
            flyoutID=flyoutID
            register=this.registerButton
          )
          to="button"
        }}
      {{/if}}

      {{#if (or @isOpen this.navIsDocked)}}
        <EuiFlyout
          id={{flyoutID}}
          class="euiCollapsibleNav"
          @css={{this.flyoutCss}}
          @as={{this.as}}
          @size={{this.size}}
          @side={{this.side}}
          @role={{this.role}}
          @ownFocus={{this.ownFocus}}
          @outsideClickCloses={{this.outsideClickCloses}}
          @closeButtonPosition={{this.closeButtonPosition}}
          @paddingSize={{this.paddingSize}}
          @type={{this.flyoutType}}
          @hideCloseButton={{this.navIsDocked}}
          @pushMinBreakpoint={{this.dockedBreakpoint}}
          @onClose={{@onClose}}
          @session={{this.session}}
          @focusTrapProps={{this.focusTrapProps}}
          @closeButtonProps={{@closeButtonProps}}
          @container={{@container}}
          @flyoutMenuDisplayMode={{@flyoutMenuDisplayMode}}
          @flyoutMenuProps={{@flyoutMenuProps}}
          @hasAnimation={{@hasAnimation}}
          @hasChildBackground={{@hasChildBackground}}
          @historyKey={{@historyKey}}
          @includeFixedHeadersInFocusTrap={{@includeFixedHeadersInFocusTrap}}
          @includeSelectorInFocusTrap={{@includeSelectorInFocusTrap}}
          @maskProps={{@maskProps}}
          @maxWidth={{@maxWidth}}
          @minWidth={{@minWidth}}
          @onActive={{@onActive}}
          @onResize={{@onResize}}
          @pushAnimation={{@pushAnimation}}
          @resizable={{@resizable}}
          ...attributes
        >
          {{yield to="content"}}
        </EuiFlyout>
      {{/if}}
    {{/let}}
  </template>
}
