import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { getTransitionTimings, getWaitDuration, performOnFrame } from 'ember-eui/utils/transition';
import { findPopoverPosition, getElementZIndex } from 'ember-eui/utils/popover';
import { EuiPopoverPosition } from 'ember-eui/utils/popover/types';
import { cascadingMenuKeys } from 'ember-eui/utils/accesibility';
import { argOrDefaultDecorator as argOrDefault } from 'ember-eui/helpers/arg-or-default';
import { tabbable } from 'tabbable';
import { anchorPositionMapping, displayMapping } from 'ember-eui/utils/css-mappings/eui-popover';
import { paddingSizeMapping } from 'ember-eui/utils/css-mappings/eui-panel';
import { scheduleOnce, later, cancel } from '@ember/runloop';
import { assert } from '@ember/debug';
import { htmlSafe } from '@ember/template';

type PanelPaddingSize = keyof typeof paddingSizeMapping;

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
   * Class name passed to the direct parent of the button
   */
  anchorClassName?: string;
  /**
   * Alignment of the popover and arrow relative to the button
   */
  anchorPosition?: PopoverAnchorPosition;
  /**
   * Style and position alteration for arrow-less, left-aligned
   * attachment. Intended for use with inputs as anchors, e.g.
   * EuiInputPopover
   */
  attachToAnchor?: boolean;
  /**
   * Triggering element for which to align the popover to
   */
  button: Component;
  buttonRef: (e: HTMLDivElement) => unknown;
  /**
   * Callback to handle hiding of the popover
   */
  closePopover: () => void;
  /**
   * Restrict the popover's position within this element
   */
  container?: HTMLElement;
  /**
   * CSS display type for both the popover and anchor
   */
  display?: keyof typeof displayMapping;
  /**
   * Show arrow indicating to originating button
   */
  hasArrow?: boolean;
  /**
   * Specifies what element should initially have focus; Can be a DOM
   * node, or a selector string (which will be passed to
   * document.querySelector() to find the DOM node), or a function that
   * returns a DOM node
   */
  initialFocus?: FocusTarget;
  /**
   * Passed directly to EuiPortal for DOM positioning. Both properties are
   * required if prop is specified
   */
  insert?: {
    sibling: HTMLElement;
    position: 'before' | 'after';
  };
  /**
   * Visibility state of the popover
   */
  isOpen?: boolean;
  /**
   * Traps tab focus within the popover contents
   */
  ownFocus?: boolean;
  /**
   * Custom class added to the EuiPanel containing the popover contents
   */
  panelClassName?: string;
  /**
   * EuiPanel padding on all sides
   */
  panelPaddingSize?: PanelPaddingSize;
  /**
   * Standard DOM `style` attribute. Passed to the EuiPanel
   */
  panelStyle?: HTMLStyleElement;
  panelRef?: (e: HTMLElement | null) => unknown;
  popoverRef?: (e: HTMLElement) => unknown;
  /**
   * When `true`, the popover's position is re-calculated when the user
   * scrolls, this supports having fixed-position popover anchors
   */
  repositionOnScroll?: boolean;
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
   * Distance away from the anchor that the popover will render
   */
  offset?: number;
  /**
   * Minimum distance between the popover and the bounding container;
   * Pass an array of 4 values to adjust each side differently: `[top, right, bottom, left]`
   * Default is 16
   */
  buffer?: number | [number, number, number, number];
  /**
   * Element to pass as the child element of the arrow;
   * Use case is typically limited to an accompanying `EuiBeacon`
   */
  arrowChildren?: Component;
  /**
   * Provide a name to the popover panel
   */
  'aria-label'?: string;
  /**
   * Alternative option to `aria-label` that takes an `id`.
   * Usually takes the `id` of the popover title
   */
  'aria-labelledby'?: string;
};

type AnchorPosition = 'up' | 'right' | 'down' | 'left';

const anchorPositionToPopoverPositionMap: {
  [position in AnchorPosition]: EuiPopoverPosition;
} = {
  up: 'top',
  right: 'right',
  down: 'bottom',
  left: 'left',
};

export function getPopoverPositionFromAnchorPosition(anchorPosition: PopoverAnchorPosition) {
  // maps the anchor position to the matching popover position
  // e.g. "upLeft" -> "top", "downRight" -> "bottom"

  // extract the first positional word from anchorPosition:
  // starts at the beginning (" ^ ") of anchorPosition and
  // captures all of the characters (" (.*?) ") until the
  // first capital letter (" [A-Z] ") is encountered
  const [, primaryPosition] = anchorPosition.match(/^(.*?)[A-Z]/)!;
  return anchorPositionToPopoverPositionMap[primaryPosition as AnchorPosition];
}

export function getPopoverAlignFromAnchorPosition(anchorPosition: PopoverAnchorPosition) {
  // maps the gravity to the matching popover position
  // e.g. "upLeft" -> "left", "rightDown" -> "bottom"

  // extract the second positional word from anchorPosition:
  // starts a capture group at the first capital letter
  // and includes everything after it
  const [, align] = anchorPosition.match(/([A-Z].*)/)!;

  // this performs two tasks:
  // 1. normalizes the align position by lowercasing it
  // 2. `center` doesn't exist in the lookup map which converts it to `undefined` meaning no align
  return anchorPositionToPopoverPositionMap[align.toLowerCase() as AnchorPosition];
}

export const ANCHOR_POSITIONS = Object.keys(anchorPositionMapping);
export const DISPLAY = Object.keys(displayMapping);
export type FocusTarget = HTMLElement | string | (() => HTMLElement);

const DEFAULT_POPOVER_STYLES = {
  top: 50,
  left: 50,
};

function getElementFromInitialFocus(initialFocus?: FocusTarget): HTMLElement | null {
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
  willChange?: string;
};

export default class EuiPopoverComponent extends Component<EuiPopoverArgs> {
  // Defaults
  @argOrDefault(false) isOpen!: boolean;
  @argOrDefault(false) ownFocus!: boolean;
  @argOrDefault('downCenter') anchorPosition!: PopoverAnchorPosition;
  @argOrDefault('m') panelPaddingSize!: PanelPaddingSize;
  @argOrDefault(true) hasArrow!: boolean;
  @argOrDefault('inlineBlock') display!: string;

  //State
  @tracked prevIsOpen: boolean | undefined;
  @tracked suppressingPopover: boolean | undefined;
  @tracked isClosing: boolean = false;
  @tracked isOpening: boolean = false;
  @tracked popoverStyles: CssProps = {};
  @tracked arrowStyles: CssProps | undefined = {};
  @tracked arrowPosition: any;
  @tracked openPosition: any;
  @tracked isOpenStable: boolean = false;
  @tracked isCurrentlyOpen: boolean | undefined;
  ///

  private respositionTimeout: any;
  private closingTransitionTimeout: any;
  private closingTransitionAnimationFrame: number | undefined;
  private updateFocusAnimationFrame: number | undefined;
  @tracked button: HTMLElement | null = null;
  @tracked panel: HTMLElement | null = null;

  constructor(owner: unknown, args: EuiPopoverArgs) {
    super(owner, args);
    assert(`Must provide closePopover function`, this.args.closePopover);
    this.prevIsOpen = this.isOpen;
    this.suppressingPopover = this.isOpen;
    this.isCurrentlyOpen = this.isOpen;
  }

  @action
  closePopover() {
    if (this.isOpen) {
      this.args.closePopover();
    }
  }

  @action
  onEscapeKey(event: Event) {
    if (this.isOpen) {
      event.preventDefault();
      event.stopPropagation();
      this.closePopover();
    }
  }

  @action
  onKeyDown(event: KeyboardEvent) {
    if (event.key === cascadingMenuKeys.ESCAPE) {
      this.onEscapeKey((event as unknown) as Event);
    }
  }

  @action
  onClickOutside(event: Event) {
    // only close the popover if the event source isn't the anchor button
    // otherwise, it is up to the anchor to toggle the popover's open status
    if (this.button && this.button.contains(event.target as Node) === false) {
      this.closePopover();
    }
  }

  updateFocus() {
    // Wait for the DOM to update.
    this.updateFocusAnimationFrame = window.requestAnimationFrame(() => {
      if (!this.ownFocus || !this.panel) {
        return;
      }

      // If we've already focused on something inside the panel, everything's fine.
      if (this.panel.contains(document.activeElement)) {
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
        const panelVisibility = window.getComputedStyle(this.panel).visibility;
        if (panelVisibility === 'hidden') {
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

      if (focusTarget != null) focusTarget.focus();
    });
  }

  @action
  onOpenPopover() {
    cancel(this.closingTransitionTimeout);
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
          { durationMatch, delayMatch }: { durationMatch: number; delayMatch: number },
          element: HTMLElement
        ) => {
          const transitionTimings = getTransitionTimings(element);

          return {
            durationMatch: Math.max(durationMatch, transitionTimings.durationMatch),
            delayMatch: Math.max(delayMatch, transitionTimings.delayMatch),
          };
        },
        { durationMatch: 0, delayMatch: 0 }
      );

    this.respositionTimeout = later(
      this,
      () => {
        this.isOpenStable = true;
        scheduleOnce('afterRender', this, () => {
          this.positionPopoverFixed();
          this.updateFocus();
        });
      },
      durationMatch + delayMatch
    );
  }

  @action
  didInsertPopover() {
    if (this.suppressingPopover) {
      // component was created with isOpen=true; now that it's inserted
      // stop suppressing and start opening
      this.suppressingPopover = false;
      this.isOpening = true;
      scheduleOnce('afterRender', this, () => {
        this.onOpenPopover();
      });
    }

    if (this.args.repositionOnScroll) {
      window.addEventListener('scroll', this.positionPopoverFixed);
    }

    this.updateFocus();
  }

  @action
  didUpdateRepositionOnScroll() {
    if (this.args.repositionOnScroll) {
      window.addEventListener('scroll', this.positionPopoverFixed);
    } else {
      window.removeEventListener('scroll', this.positionPopoverFixed);
    }
  }

  @action
  didUpdateIsOpen() {
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
        250
      );
    }
    this.prevIsOpen = this.args.isOpen;
  }

  willDestroy() {
    super.willDestroy();
    window.removeEventListener('scroll', this.positionPopoverFixed);
    cancel(this.respositionTimeout);
    cancel(this.closingTransitionTimeout);
    cancelAnimationFrame(this.closingTransitionAnimationFrame!);
    cancelAnimationFrame(this.updateFocusAnimationFrame!);
  }

  @action
  onMutation(records: MutationRecord[]) {
    const waitDuration = getWaitDuration(records);
    this.positionPopoverFixed();

    performOnFrame(waitDuration, this.positionPopoverFixed);
  }

  @action
  positionPopover(allowEnforcePosition: boolean) {
    if (this.button == null || this.panel == null) return;

    let position = getPopoverPositionFromAnchorPosition(this.anchorPosition);
    let forcePosition = undefined;
    if (allowEnforcePosition && this.isOpenStable && this.openPosition != null) {
      position = this.openPosition;
      forcePosition = true;
    }

    const { top, left, position: foundPosition, arrow, anchorBoundingBox } = findPopoverPosition({
      container: this.args.container,
      position,
      forcePosition,
      align: getPopoverAlignFromAnchorPosition(this.anchorPosition),
      anchor: this.button,
      popover: this.panel,
      offset:
        !this.args.attachToAnchor && this.hasArrow
          ? 16 + (this.args.offset || 0)
          : 8 + (this.args.offset || 0),
      arrowConfig: {
        arrowWidth: 24,
        arrowBuffer: 10,
      },
      returnBoundingBox: this.args.attachToAnchor,
      buffer: this.args.buffer,
    });

    // the popover's z-index must inherit from the button
    // this keeps a button's popover under a flyout that would cover the button
    // but a popover triggered inside a flyout will appear over that flyout
    const { zIndex: zIndexProp } = this.args;
    const zIndex =
      zIndexProp == null ? getElementZIndex(this.button, this.panel) + 2000 : zIndexProp;

    const popoverStyles = {
      top,
      left: this.args.attachToAnchor && anchorBoundingBox ? anchorBoundingBox.left : left,
      zIndex,
      // Adding `will-change` to reduce risk of a blurry animation in Chrome 86+
      willChange: 'transform, opacity',
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
    let { arrowStyles } = this;
    return arrowStyles
      ? htmlSafe(`top: ${arrowStyles?.top}px; left: ${arrowStyles?.left}px;`)
      : undefined;
  }
  get _popoverStyles(): {} {
    let { panelStyle } = this.args;
    let { popoverStyles } = this;
    return {
      ...panelStyle,
      top: `${popoverStyles.top}px`,
      left: `${popoverStyles.left}px`,
      zIndex: `${popoverStyles.zIndex}`,
      willChange: 'transform, opacity',
    };
  }

  @action
  positionPopoverFixed() {
    this.positionPopover(true);
  }

  @action
  positionPopoverFluid() {
    this.positionPopover(false);
  }

  @action
  registerButton(btn: HTMLDivElement) {
    this.button = btn;
    this.args.buttonRef?.(btn);
  }

  @action
  registerPanel(panel: HTMLElement | null) {
    this.panel = panel;
    this.args.panelRef?.(panel);
    if (panel == null) {
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
}
