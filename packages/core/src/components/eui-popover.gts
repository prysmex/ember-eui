import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';
import { hash } from '@ember/helper';
import { concat } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { cancel, later, scheduleOnce } from '@ember/runloop';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';
import { buildWaiter } from '@ember/test-waiters';
import type Owner from '@ember/owner';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { focusTrap } from 'ember-focus-trap';
import { modifier } from 'ember-modifier';
import {
  attachToFocusTraps,
  focusTrapFactory
} from '../-private/focus-trap-registry.ts';
import { provide } from 'ember-provide-consume-context';
import onKey from 'ember-keyboard/modifiers/on-key';
import { and, not, or } from 'ember-truth-helpers';
import { focusable, tabbable } from 'tabbable';

import { EUI_POPOVER_PANEL_CONTEXT } from '../-private/eui-popover-panel-context.ts';
import { randomId as generateId } from '../-private/random-id.ts';
import { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import merge from '../helpers/merge.ts';
import mutationObserver from '../modifiers/mutation-observer.ts';
import outsideClickDetector from '../modifiers/outside-click-detector.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import simpleStyle from '../modifiers/simple-style.ts';
import { cascadingMenuKeys } from '../utils/accesibility/index.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiBackgroundColor,
  euiBorderColor,
  euiPaddingSize,
  euiPanelStyles,
  euiPopoverArrowStyles,
  euiPopoverPanelStyles,
  euiPopoverStyles
} from '../utils/eui/styles.generated.ts';
import {
  findPopoverPosition,
  getElementZIndex
} from '../utils/popover/index.ts';
import {
  getTransitionTimings,
  getWaitDuration,
  performOnFrame
} from '../utils/transition.ts';
import EuiPortal from './eui-portal.gts';

import type {
  EuiPopoverPanelContext,
  EuiPopoverPanelPaddingSize
} from '../-private/eui-popover-panel-context.ts';
import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiPopoverPosition } from '../utils/popover/types';
import type { EmberKeyboardEvent } from 'ember-keyboard/modifiers/on-key';

/** Panel padding; `xs`/`xl` exist upstream but are discouraged. */
type PanelPaddingSize = EuiPopoverPanelPaddingSize;

/** `'inlineBlock'`/`'block'`, or any CSS `display` value (upstream). */
type PopoverDisplay = 'inlineBlock' | 'block' | (string & {});

export type PopoverAnchorPosition =
  | 'upCenter'
  | 'upLeft'
  | 'upRight'
  | 'downCenter'
  | 'downLeft'
  | 'downRight'
  | 'leftCenter'
  | 'leftUp'
  | 'leftDown'
  | 'rightCenter'
  | 'rightUp'
  | 'rightDown';

export type EuiPopoverArgs = {
  /**
   * Callback to have a reference to the portal element
   */
  portalRef?: (ref: HTMLElement) => void;
  /**
   * Class name passed to the direct parent of the button
   */
  anchorClassName?: string;
  /**
   * Where the popover opens relative to the button: `'upCenter'`,
   * `'upLeft'`, `'upRight'`, `'downCenter'`, `'downLeft'`, `'downRight'`,
   * `'leftCenter'`, `'leftUp'`, `'leftDown'`, `'rightCenter'`, `'rightUp'`
   * or `'rightDown'`. It flips when there is no room. Defaults to
   * `'downLeft'` (upstream EUI default).
   */
  anchorPosition?: PopoverAnchorPosition;
  /**
   * Style and position alteration for arrow-less, left-aligned
   * attachment. Intended for use with inputs as anchors, e.g.
   * EuiInputPopover
   */
  attachToAnchor?: boolean;
  /**
   * Element to align the popover to, instead of the `<:button>` block's
   * content.
   */
  button?: HTMLElement;
  /** Called with the element wrapping the `<:button>` block. */
  buttonRef?: (e: HTMLDivElement) => unknown;
  /**
   * Called to close the popover (Escape, clicks outside); set `@isOpen` to
   * `false` here.
   */
  closePopover: () => void;
  /**
   * Restrict the popover's position within this element
   */
  container?: HTMLElement;
  /**
   * CSS display of the popover's root: `'inlineBlock'`, `'block'` or any
   * CSS `display` value. Defaults to `'inlineBlock'`.
   */
  display?: PopoverDisplay;
  /**
   * Show an arrow pointing to the anchor. Defaults to `false` (upstream EUI
   * default).
   */
  hasArrow?: boolean;
  /**
   * The element to focus when the popover opens: a DOM node, a selector
   * (for `document.querySelector()`) or a function returning a node. It is
   * focused once the panel is positioned and visible (so the page does not
   * scroll to a panel still being placed), also without `@ownFocus`.
   * `false` focuses nothing.
   */
  initialFocus?: FocusTarget | false;
  /**
   * Passed directly to EuiPortal for DOM positioning. Both properties are
   * required if prop is specified
   */
  insert?: {
    sibling: HTMLElement;
    position: 'before' | 'after';
  };
  /**
   * Whether the popover is open. Toggle it from the `<:button>` block's
   * button. Defaults to `false`.
   */
  isOpen?: boolean;
  /**
   * Traps tab focus within the popover contents. Defaults to `true`.
   */
  ownFocus?: boolean;
  /**
   * Custom class added to the panel containing the popover contents
   */
  panelClassName?: string;
  /**
   * Padding of the popover: `'none'`, `'s'`, `'m'` or `'l'` (`'xs'` and
   * `'xl'` are discouraged upstream). Defaults to `'m'`.
   */
  panelPaddingSize?: PanelPaddingSize;
  /** Inline styles for the panel (positioning styles win). */
  panelStyle?: { [i: string]: string };
  /**
   * Extra screen reader text, announced with the panel (with `@ownFocus`
   * it follows the default "You are in a dialog…" instructions).
   */
  popoverScreenReaderText?: string;
  /** Called with the popover's panel element (`null` when it closes). */
  panelRef?: (e: HTMLElement | null) => unknown;
  /** Called with the popover's root element. */
  popoverRef?: (e: HTMLElement) => unknown;

  /**
   * When not `false`, a popover opened from inside another popover
   * positions itself relative to that one. Defaults to `true`.
   */
  shouldAccountForOtherPopovers?: boolean;

  /**
   * When `true`, the popover's position is re-calculated when the user
   * scrolls, this supports having fixed-position popover anchors
   */
  repositionOnScroll?: boolean;
  /**
   * Whether the popover may move to the cross axis (e.g. from below to the
   * side of the anchor) when there is no room. Defaults to `true`.
   */
  repositionToCrossAxis?: boolean;
  /**
   * @private Styles composed last into the root's class (e.g.
   * EuiInputPopover's max width), like upstream's `css` prop.
   */
  rootCss?: EuiCss;
  /**
   * Extra styles composed last into the root's class (like upstream's `css`
   * prop). Prefer this to an extra class when styling it from a parent.
   */
  css?: EuiCss;
  /**
   * Extra styles composed last into the panel's class (like upstream's
   * `panelProps.css`). Prefer this to `@panelClassName` for styles.
   */
  panelCss?: EuiCss;
  /**
   * By default, popover content inherits the z-index of the anchor
   * component; pass `zIndex` to override
   */
  zIndex?: number;
  /**
   * Function callback for when the focus trap is deactivated
   */
  onTrapDeactivation?: () => void;
  /**
   * Distance away from the anchor that the popover will render. Defaults
   * to `0` with an arrow and `4` without (upstream).
   */
  offset?: number;
  /**
   * Minimum distance between the popover and the bounding container;
   * Pass an array of 4 values to adjust each side differently: `[top, right, bottom, left]`
   * Default is 16
   */
  buffer?: number | [number, number, number, number];
  /** @deprecated Has no effect, use the `<:arrowChildren>` block. */
  arrowChildren?: Component;
  /**
   * Provide a name to the popover panel
   */
  ariaLabel?: string;
  /**
   * Alternative option to `aria-label` that takes an `id`.
   * Usually takes the `id` of the popover title
   */
  ariaLabelledBy?: string;

  /** `tabindex` of the panel. Defaults to `'0'`. */
  tabindex?: string | number;

  /** Focuses the panel itself when it opens. Defaults to `true`. */
  shouldSelfFocus?: boolean;

  /** Pauses the focus trap, e.g. while a nested popover has focus. */
  isFocusTrapPaused?: boolean;

  /** Options for the focus trap (focus-trap library). */
  focusTrapOptions?: {
    [key: string]: any;
    onClickOutside?: (e: Event) => void;
  };

  /**
   * What content changes reposition the popover (MutationObserver
   * options). Defaults to watching the panel's subtree.
   */
  mutationObserverOptions?: {
    attributes?: boolean;
    childList?: boolean;
    characterData?: boolean;
    subtree?: boolean;
  };
};

type AnchorPosition = 'up' | 'right' | 'down' | 'left';

const anchorPositionToPopoverPositionMap: {
  [position in AnchorPosition]: EuiPopoverPosition;
} = {
  up: 'top',
  right: 'right',
  down: 'bottom',
  left: 'left'
};

export function getPopoverPositionFromAnchorPosition(
  anchorPosition: PopoverAnchorPosition
): EuiPopoverPosition {
  // maps the anchor position to the matching popover position
  // e.g. "upLeft" -> "top", "downRight" -> "bottom"

  // extract the first positional word from anchorPosition:
  // starts at the beginning (" ^ ") of anchorPosition and
  // captures all of the characters (" (.*?) ") until the
  // first capital letter (" [A-Z] ") is encountered
  const match = anchorPosition.match(/^(.*?)[A-Z]/);

  if (match?.length && match.length > 1) {
    return anchorPositionToPopoverPositionMap[match[1] as AnchorPosition];
  }

  return anchorPositionToPopoverPositionMap['up'];
}

export function getPopoverAlignFromAnchorPosition(
  anchorPosition: PopoverAnchorPosition
): EuiPopoverPosition {
  // maps the gravity to the matching popover position
  // e.g. "upLeft" -> "left", "rightDown" -> "bottom"

  // extract the second positional word from anchorPosition:
  // starts a capture group at the first capital letter
  // and includes everything after it
  const match = anchorPosition.match(/([A-Z].*)/);

  // this performs two tasks:
  // 1. normalizes the align position by lowercasing it
  // 2. `center` doesn't exist in the lookup map which converts it to `undefined` meaning no align
  if (match?.length && match.length > 1) {
    return anchorPositionToPopoverPositionMap[
      match[1]?.toLowerCase() as AnchorPosition
    ];
  }

  return anchorPositionToPopoverPositionMap['left'];
}

export const ANCHOR_POSITIONS: PopoverAnchorPosition[] = [
  'upCenter',
  'upLeft',
  'upRight',
  'downCenter',
  'downLeft',
  'downRight',
  'leftCenter',
  'leftUp',
  'leftDown',
  'rightCenter',
  'rightUp',
  'rightDown'
];
export const DISPLAY = ['inlineBlock', 'block'];

/** Ember display names mapped to the CSS values upstream takes. */
const DISPLAY_CSS: Record<string, string> = {
  inlineBlock: 'inline-block',
  block: 'block'
};

/** Upstream `EuiPopover` closing transition time (ms). */
const CLOSING_TRANSITION_TIME = 250;
// tests settle once an opening popover has set its focus
const focusWaiter = buildWaiter('@ember-eui/core:eui-popover-focus');

export type FocusTarget = HTMLElement | string | (() => HTMLElement | null);

const DEFAULT_POPOVER_STYLES = {
  top: 50,
  left: 50
};

function getElementFromInitialFocus(
  initialFocus?: FocusTarget
): HTMLElement | null {
  const initialFocusType = typeof initialFocus;

  if (initialFocusType === 'string') {
    return document.querySelector(initialFocus as string);
  }

  if (initialFocusType === 'function') {
    return (initialFocus as () => HTMLElement | null)();
  }

  return initialFocus as HTMLElement | null;
}

type CssProps = {
  top?: number;
  left?: number;
  right?: number;
  bottom?: number;
  zIndex?: number;
};

/**
 * A floating panel anchored to a button, e.g. a menu or a small form. You
 * control `@isOpen` and close it in `@closePopover`.
 */
export interface EuiPopoverSignature {
  Element: HTMLDivElement;
  Args: EuiPopoverArgs;
  Blocks: {
    /**
     * The element opening the popover, e.g.
     * `<EuiButton {{on "click" (set this "isOpen" true)}}>`.
     */
    button: [];
    /** The popover's content. */
    content: [];
    /** Content inside the arrow (rarely needed). */
    arrowChildren: [];
  };
}

export default class EuiPopoverComponent
  extends Component<EuiPopoverSignature>
  implements EuiPopoverPanelContext
{
  @service declare euiI18n: EuiI18n;

  /** EuiPopoverTitle/Footer inherit the panel padding (upstream context). */
  @provide(EUI_POPOVER_PANEL_CONTEXT)
  get panelContext(): EuiPopoverPanelContext {
    return this;
  }

  get paddingSize(): PanelPaddingSize {
    return this.panelPaddingSize;
  }

  /** Id of the panel, for the trigger's `aria-controls`. */
  panelId = generateId();
  /** Id of the screen reader description. */
  descriptionId = generateId();

  // Defaults
  @argOrDefaultDecorator(false) isOpen!: boolean;
  @argOrDefaultDecorator(true) ownFocus!: boolean;
  @argOrDefaultDecorator('downLeft') anchorPosition!: PopoverAnchorPosition;
  @argOrDefaultDecorator('m') panelPaddingSize!: PanelPaddingSize;
  @argOrDefaultDecorator(false) hasArrow!: boolean;
  @argOrDefaultDecorator('inlineBlock') display!: string;
  @argOrDefaultDecorator(true) shouldSelfFocus!: boolean;
  @argOrDefaultDecorator(false) isFocusTrapPaused!: boolean;

  //State
  @tracked prevIsOpen: boolean | undefined;
  @tracked suppressingPopover: boolean | undefined;
  @tracked isClosing = false;
  @tracked isOpening = false;
  @tracked popoverStyles: CssProps = {};
  @tracked arrowStyles: CssProps | undefined = {};
  @tracked arrowPosition: EuiPopoverPosition | null = null;
  @tracked openPosition: EuiPopoverPosition | null = null;
  @tracked isOpenStable = false;
  @tracked isCurrentlyOpen: boolean | undefined;
  @tracked popoverHost?: HTMLElement | null = null;
  ///

  private respositionTimeout: ReturnType<typeof later> | null = null;
  private closingTransitionTimeout: ReturnType<typeof later> | null = null;
  private closingTransitionAnimationFrame: number | undefined;
  private updateFocusAnimationFrame: number | undefined;
  private updateFocusToken: unknown;
  private hasSetInitialFocus: boolean = false;
  @tracked _button: HTMLElement | null = null;

  /**
   * The portalled panel counts as inside the modal, flyout or popover focus
   * trap its anchor is in (upstream's react-focus-on follows React portals).
   */
  joinFocusTraps = modifier((panel: HTMLElement) =>
    attachToFocusTraps(this._button, panel)
  );
  @tracked panel: HTMLElement | null = null;

  constructor(owner: Owner, args: EuiPopoverArgs) {
    super(owner, args);
    assert(`Must provide closePopover function`, this.args.closePopover);
    this.prevIsOpen = this.isOpen;
    this.suppressingPopover = this.isOpen;
    this.isCurrentlyOpen = this.isOpen;
  }

  get button() {
    if (this.args.button) {
      return this.args.button;
    }

    return this._button;
  }

  get insert() {
    if (this.args.insert) {
      return this.args.insert;
    }

    if (this.shouldAccountForOtherPopovers) {
      if (this.popoverHost) {
        return {
          sibling: this.popoverHost.children[0] as HTMLElement,
          position: 'after'
        };
      }
    }

    return undefined;
  }

  @action
  closePopover(): void {
    if (this.isOpen) {
      this.args.closePopover();
    }
  }

  @action
  onEscapeKey(event: Event, ekEvent?: EmberKeyboardEvent): void {
    if (this.isOpen) {
      ekEvent?.stopPropagation();
      ekEvent?.stopImmediatePropagation();
      event.preventDefault();
      event.stopPropagation();
      this.closePopover();
    }
  }

  @action
  onKeyDown(event: KeyboardEvent, ekEvent: EmberKeyboardEvent): void {
    if (event.key === cascadingMenuKeys.ESCAPE) {
      this.onEscapeKey(event as unknown as Event, ekEvent as unknown as Event);
    }
  }

  @action
  onClickOutside(event: Event): void {
    if (this.args.focusTrapOptions?.onClickOutside) {
      this.args.focusTrapOptions.onClickOutside(event);
    } else {
      // only close the popover if the event source isn't the anchor button
      // otherwise, it is up to the anchor to toggle the popover's open status
      if (this.button && this.button.contains(event.target as Node) === false) {
        this.closePopover();
      }
    }
  }

  private cancelUpdateFocus(): void {
    cancelAnimationFrame(this.updateFocusAnimationFrame as number);

    if (this.updateFocusToken) {
      focusWaiter.endAsync(this.updateFocusToken);
      this.updateFocusToken = undefined;
    }
  }

  updateFocus(): void {
    this.cancelUpdateFocus();

    const token = focusWaiter.beginAsync();

    this.updateFocusToken = token;
    // Wait for the DOM to update.
    this.updateFocusAnimationFrame = window.requestAnimationFrame(() => {
      focusWaiter.endAsync(token);
      this.updateFocusToken = undefined;

      // without @ownFocus, only an explicit @initialFocus moves the focus
      const hasInitialFocus =
        this.args.initialFocus !== undefined && this.args.initialFocus !== null;

      if (
        !(this.ownFocus || hasInitialFocus) ||
        !this.panel ||
        this.args.initialFocus === false
      ) {
        return;
      }

      // If we've already focused on something inside the panel, everything's fine.
      if (
        this.hasSetInitialFocus &&
        this.panel.contains(document.activeElement)
      ) {
        return;
      }

      // Otherwise let's focus the first tabbable item and expedite input from the user.
      let focusTarget;

      if (this.args.initialFocus != null) {
        focusTarget = getElementFromInitialFocus(this.args.initialFocus);
      } else {
        const tabbableItems = tabbable(this.panel);

        if (tabbableItems.length) {
          focusTarget = tabbableItems[0];
        }
      }

      // there's a race condition between the popover content becoming visible and this function call
      // if the element isn't visible yet (due to css styling) then it can't accept focus
      // so wait for another render and try again
      if (focusTarget == null) {
        // there isn't a focus target, one of two reasons:
        // #1 is the whole panel hidden? If so, schedule another check
        // #2 panel is visible but no tabbables exist, move focus to the panel
        const panelVisibility = window.getComputedStyle(this.panel).opacity;

        if (panelVisibility === '0') {
          // #1
          this.updateFocus();
        } else {
          // #2
          focusTarget = this.panel;
        }
      } else {
        // found an element to focus, but is it visible?
        const visibility = window.getComputedStyle(focusTarget).visibility;

        if (visibility === 'hidden') {
          // not visible, check again next render frame
          this.updateFocus();
        }
      }

      if (focusTarget != null) {
        this.hasSetInitialFocus = true;
        focusTarget.focus();
      }
    });
  }

  @action
  onOpenPopover(): void {
    cancel(this.closingTransitionTimeout as ReturnType<typeof later>);
    // We need to set this state a beat after the render takes place, so that the CSS
    // transition can take effect.
    this.closingTransitionAnimationFrame = window.requestAnimationFrame(() => {
      this.isOpening = true;
    });

    // for each child element of `this.panel`, find any transition duration we should wait for before stabilizing
    const { durationMatch, delayMatch } = Array.prototype.slice
      .call(this.panel ? this.panel.children : [])
      .reduce(
        (
          {
            durationMatch,
            delayMatch
          }: { durationMatch: number; delayMatch: number },
          element: HTMLElement
        ) => {
          const transitionTimings = getTransitionTimings(element);

          return {
            durationMatch: Math.max(
              durationMatch,
              transitionTimings.durationMatch
            ),
            delayMatch: Math.max(delayMatch, transitionTimings.delayMatch)
          };
        },
        { durationMatch: 0, delayMatch: 0 }
      );

    this.respositionTimeout = later(
      this,
      () => {
        this.isOpenStable = true;

        const fn = (): void => {
          this.positionPopoverFixed();
          this.updateFocus();
        };

        scheduleOnce('afterRender', this, fn);
      },
      durationMatch + delayMatch
    );
  }

  get shouldAccountForOtherPopovers() {
    return this.args.shouldAccountForOtherPopovers ?? true;
  }

  checkIfPopoverIsInsideAnotherPopover(ele: HTMLElement) {
    const otherPopover = ele.closest<HTMLDivElement>('div.euiPopover__panel');

    this.popoverHost = otherPopover;
  }

  @action
  didInsertPopover(ele: HTMLDivElement): void {
    if (this.suppressingPopover) {
      // component was created with isOpen=true; now that it's inserted
      // stop suppressing and start opening
      this.suppressingPopover = false;
      this.isOpening = true;

      const fn = (): void => this.onOpenPopover();

      scheduleOnce('afterRender', this, fn);
    }

    if (this.args.repositionOnScroll) {
      window.addEventListener('scroll', this.positionPopoverFixed, true);
    }

    if (this.shouldAccountForOtherPopovers) {
      this.checkIfPopoverIsInsideAnotherPopover(ele);
    }

    this.updateTriggerAria();
    this.updateFocus();
  }

  @action
  didUpdateRepositionOnScroll(): void {
    if (this.args.repositionOnScroll) {
      window.addEventListener('scroll', this.positionPopoverFixed, true);
    } else {
      window.removeEventListener('scroll', this.positionPopoverFixed, true);
    }
  }

  @action
  didUpdateIsOpen(): void {
    this.isCurrentlyOpen = this.isOpen;

    if (!this.prevIsOpen && this.args.isOpen) {
      this.onOpenPopover();
    }

    if (this.prevIsOpen && !this.args.isOpen) {
      // If the user has just closed the popover, queue up the removal of the content after the
      // transition is complete.
      this.isClosing = true;
      this.isOpening = false;
      this.closingTransitionTimeout = later(
        this,
        () => {
          this.isClosing = false;
        },
        CLOSING_TRANSITION_TIME
      );
    }

    if (!!this.prevIsOpen !== !!this.args.isOpen) {
      this.updateTriggerAria();
    }

    this.prevIsOpen = this.args.isOpen;
  }

  /**
   * Upstream: the first focusable element of the anchor, when it is a
   * button (or `role="button"`), gets `aria-expanded`, and `aria-controls`
   * pointing at the panel while open. Inputs and other elements are left
   * alone.
   */
  getFocusableToggleButton(): HTMLElement | undefined {
    const anchor = this.args.button ?? this._button;

    if (!anchor) return undefined;

    try {
      return focusable(anchor, { includeContainer: !!this.args.button })[0] as
        | HTMLElement
        | undefined;
    } catch {
      return undefined;
    }
  }

  @action
  updateTriggerAria(): void {
    const toggleButton = this.getFocusableToggleButton();

    if (!toggleButton) return;

    const tag = toggleButton.tagName.toLowerCase();
    const role = toggleButton.getAttribute('role')?.toLowerCase();

    if (tag !== 'button' && role !== 'button') return;

    toggleButton.setAttribute('aria-expanded', this.isOpen ? 'true' : 'false');

    if (this.isOpen) {
      toggleButton.setAttribute('aria-controls', this.panelId);
    } else {
      toggleButton.removeAttribute('aria-controls');
    }
  }

  /** Upstream repositions an open popover when these args change. */
  @action
  didUpdatePlacementArgs(): void {
    if (this.isOpen) this.positionPopoverFluid();
  }

  willDestroy(): void {
    super.willDestroy();
    window.removeEventListener('scroll', this.positionPopoverFixed, true);
    window.removeEventListener('resize', this.positionPopoverFluid);
    this.popoverHost = null;
    this._button = null;
    this.panel = null;
    cancel(this.respositionTimeout as ReturnType<typeof later>);
    cancel(this.closingTransitionTimeout as ReturnType<typeof later>);
    cancelAnimationFrame(this.closingTransitionAnimationFrame as number);
    this.cancelUpdateFocus();
  }

  @action
  onMutation(records: MutationRecord[]): void {
    const waitDuration = getWaitDuration(records);

    this.positionPopoverFixed();

    performOnFrame(waitDuration, this.positionPopoverFixed);
  }

  @action
  positionPopover(allowEnforcePosition: boolean): void {
    if (this.button == null || this.panel == null) return;

    // upstream: no extra distance by default with an arrow, 4px without
    const offset = this.args.offset ?? (this.hasArrow ? 0 : 4);
    let position = getPopoverPositionFromAnchorPosition(this.anchorPosition);
    let forcePosition = undefined;

    if (
      allowEnforcePosition &&
      this.isOpenStable &&
      this.openPosition != null
    ) {
      position = this.openPosition;
      forcePosition = true;
    }

    const {
      top,
      left,
      position: foundPosition,
      arrow,
      anchorBoundingBox
    } = findPopoverPosition({
      container: this.args.container,
      host: this.shouldAccountForOtherPopovers ? this.popoverHost : null,
      position,
      forcePosition,
      align: getPopoverAlignFromAnchorPosition(this.anchorPosition),
      anchor: this.button,
      popover: this.panel,
      offset: this.args.attachToAnchor
        ? offset
        : this.hasArrow
          ? 16 + offset
          : 8 + offset,
      // upstream Borealis arrow: 16px wide, kept out of the 12px corners
      arrowConfig: this.hasArrow
        ? { arrowWidth: 16, arrowBuffer: 10, borderRadius: 12 }
        : { arrowWidth: 0, arrowBuffer: 0 },
      returnBoundingBox: this.args.attachToAnchor,
      allowCrossAxis: this.args.repositionToCrossAxis ?? true,
      buffer: this.args.buffer
    });

    // the popover's z-index must inherit from the button
    // this keeps a button's popover under a flyout that would cover the button
    // but a popover triggered inside a flyout will appear over that flyout
    const { zIndex: zIndexProp } = this.args;
    const zIndex =
      zIndexProp == null
        ? getElementZIndex(this.button, this.panel) + 2000
        : zIndexProp;

    const popoverStyles = {
      top,
      left:
        this.args.attachToAnchor && anchorBoundingBox
          ? anchorBoundingBox.left
          : left,
      zIndex
    };

    const willRenderArrow = !this.args.attachToAnchor && this.hasArrow;
    const arrowStyles = willRenderArrow ? arrow : undefined;
    const arrowPosition = foundPosition;

    this.popoverStyles = popoverStyles;
    this.arrowStyles = arrowStyles;
    this.arrowPosition = arrowPosition;
    this.openPosition = foundPosition;
  }

  get _arrowStyles(): ReturnType<typeof htmlSafe> | undefined {
    const { arrowStyles } = this;

    return arrowStyles
      ? htmlSafe(`top: ${arrowStyles?.top}px; left: ${arrowStyles?.left}px;`)
      : undefined;
  }

  get _popoverStyles(): { [i: string]: string } {
    const { panelStyle } = this.args;
    const { popoverStyles } = this;

    return {
      ...panelStyle,
      top: `${popoverStyles.top}px`,
      left: `${popoverStyles.left}px`,
      zIndex: `${popoverStyles.zIndex}`,
      // upstream: reduces the risk of a blurry animation in Chrome 86+
      willChange: this.isOpenStable ? 'auto' : 'transform, opacity'
    };
  }

  get showArrow(): boolean {
    return this.hasArrow && !this.args.attachToAnchor;
  }

  /** Root: upstream `euiPopoverStyles` plus the display. */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPopoverStyles);
    const display = DISPLAY_CSS[this.display] ?? this.display;

    return `euiPopover ${euiClass(
      context,
      styles.euiPopover,
      { display, label: display },
      this.args.rootCss,
      this.args.css
    )}`;
  }

  /**
   * The panel: upstream `EuiPopoverPanel`, i.e. an `EuiPanel` (plain, no
   * shadow or border, padding and radius m) composed with the popover panel
   * styles in a single class, so no rule order between two classes matters.
   */
  @cached
  get panelClasses(): string {
    const context = getEuiThemeContext(this);
    const upstream = context.upstream;
    const panel = useEuiBorealisStyles(context, euiPanelStyles);
    const styles = useEuiBorealisStyles(context, euiPopoverPanelStyles);
    const isOpen = this.isOpening;
    const position = this.arrowPosition;
    const colorMode = upstream.colorMode === 'DARK' ? 'dark' : 'light';
    const generated = euiClass(
      context,
      // no React global reset; portaled content also leaves the provider's
      // color wrapper, so the panel sets the theme's text color itself
      {
        boxSizing: 'border-box',
        color: upstream.euiTheme.colors.textParagraph,
        textAlign: 'start'
      },
      panel.euiPanel,
      panel.grow,
      panel.radius.m,
      { padding: euiPaddingSize(upstream, this.panelPaddingSize) ?? 0 },
      { backgroundColor: euiBackgroundColor(upstream, 'plain') },
      upstream.highContrastMode && {
        border: upstream.euiTheme.border.thin,
        borderColor: euiBorderColor(upstream, 'plain')
      },
      styles.euiPopover__panel,
      styles[colorMode],
      isOpen && styles.isOpen,
      ...(this.args.attachToAnchor
        ? [styles.isAttached.isAttached, position && styles.isAttached[position]]
        : [
            styles.hasTransform.hasTransform,
            isOpen && position && styles.hasTransform[position]
          ]),
      this.args.panelCss
    );

    return [
      'euiPanel euiPanel--plain euiPopover__panel',
      this.args.panelClassName,
      generated
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get arrowClasses(): { wrapper: string; arrow: string } | undefined {
    const position = this.arrowPosition;

    if (!position) return undefined;

    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPopoverArrowStyles);

    return {
      wrapper: `euiPopover__arrowWrapper ${euiClass(context, styles.euiPopoverArrowWrapper)}`,
      arrow: `euiPopover__arrow ${euiClass(context, styles.euiPopoverArrow, styles[position])}`
    };
  }

  get screenReaderAnnouncement(): string {
    return this.euiI18n.lookupToken(
      'euiPopover.screenReaderAnnouncement',
      'You are in a dialog. Press Escape, or tap/click outside the dialog to close.'
    );
  }

  get hasDescription(): boolean {
    return this.ownFocus || !!this.args.popoverScreenReaderText;
  }

  get tabindex() {
    if (this.ownFocus) {
      return this.args.tabindex ?? '0';
    }

    return '-1';
  }

  @action
  positionPopoverFixed(): void {
    this.positionPopover(true);
  }

  @action
  positionPopoverFluid(): void {
    this.positionPopover(false);
  }

  @action
  registerButton(btn: HTMLDivElement): void {
    this._button = btn;
    this.args.buttonRef?.(btn);
  }

  @action
  registerPanel(panel: HTMLElement): void {
    this.panel = panel;
    this.args.panelRef?.(panel);

    if (panel === null) {
      // panel has unmounted, restore the state defaults
      this.popoverStyles = DEFAULT_POPOVER_STYLES;
      this.arrowStyles = {};
      this.arrowPosition = null;
      this.openPosition = null;
      this.isOpenStable = false;
      window.removeEventListener('resize', this.positionPopoverFluid);
    } else {
      // panel is coming into existence
      this.positionPopoverFluid();
      window.addEventListener('resize', this.positionPopoverFluid);
    }
  }

  <template>
    <div
      class="{{this.classes}} {{if this.isOpening 'euiPopover-isOpen'}}"
      {{onKey "_all" this.onKeyDown priority=1}}
      {{didInsert this.didInsertPopover}}
      {{didUpdate this.didUpdateIsOpen @isOpen}}
      {{didUpdate this.didUpdateRepositionOnScroll @repositionOnScroll}}
      {{didUpdate
        this.didUpdatePlacementArgs
        @anchorPosition
        @buffer
        @offset
        @panelPaddingSize
      }}
      {{didInsert (optional @popoverRef)}}
      ...attributes
    >

      {{! button }}
      {{#if (has-block "button")}}
        <div
          class="euiPopover__anchor {{@anchorClassName}}"
          {{didInsert this.registerButton}}
        >
          {{yield to="button"}}
        </div>
      {{/if}}

      {{! content }}
      {{#if
        (and
          (not this.suppressingPopover) (or this.isCurrentlyOpen this.isClosing)
        )
      }}
        <EuiPortal @insert={{this.insert}} @portalRef={{@portalRef}}>
          <div
            id={{this.panelId}}
            class={{this.panelClasses}}
            data-popover-panel="true"
            data-popover-open={{if this.isOpening "true"}}
            aria-live={{if this.ownFocus "off" "assertive"}}
            role="dialog"
            aria-label={{@ariaLabel}}
            aria-labelledby={{@ariaLabelledBy}}
            aria-modal="true"
            aria-describedby={{if this.hasDescription this.descriptionId}}
            tabindex={{this.tabindex}}
            {{simpleStyle this._popoverStyles}}
            {{didInsert this.registerPanel}}
            {{this.joinFocusTraps}}
            {{outsideClickDetector onOutsideClick=this.onClickOutside}}
            {{onKey "Escape" this.onEscapeKey}}
            {{! the trap only traps: updateFocus sets the initial focus,
                    once the panel is positioned and visible }}
            {{focusTrap
          _createFocusTrap=focusTrapFactory
              isActive=(not
                (or (not this.ownFocus) (not this.isOpenStable) this.isClosing)
              )
              shouldSelfFocus=this.shouldSelfFocus
              isPaused=this.isFocusTrapPaused
              focusTrapOptions=(merge
                (hash
                  returnFocusOnDeactivate=this.isOpenStable
                  initialFocus=false
                  onDeactivate=(optional @onTrapDeactivation)
                  preventScroll=true
                  clickOutsideDeactivates=true
                  fallbackFocus=(concat "#" this.panelId)
                )
                @focusTrapOptions
              )
            }}
          >
            {{#if this.showArrow}}
              {{#if this.arrowClasses}}
                <div
                  class={{this.arrowClasses.wrapper}}
                  style={{this._arrowStyles}}
                >
                  <div
                    class={{this.arrowClasses.arrow}}
                    data-popover-arrow={{this.arrowPosition}}
                  ></div>
                  {{yield to="arrowChildren"}}
                </div>
              {{/if}}
            {{/if}}
            {{#if this.hasDescription}}
              <p id={{this.descriptionId}} {{screenReaderOnly}}>
                {{#if this.ownFocus}}{{this.screenReaderAnnouncement}}{{/if}}
                {{@popoverScreenReaderText}}
              </p>
            {{/if}}
            <div
              {{mutationObserver
                onMutation=this.onMutation
                observerOptions=(merge
                  (hash
                    attributes=true childList=true characterData=true subtree=true
                  )
                  @mutationObserverOptions
                )
              }}
            >
              {{yield to="content"}}
            </div>
          </div>
        </EuiPortal>
      {{/if}}

    </div>
  </template>
}
