import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';
import { hash } from '@ember/helper';
import { concat } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { cancel, later, scheduleOnce } from '@ember/runloop';
import { htmlSafe } from '@ember/template';

import optional from 'ember-composable-helpers/helpers/optional';
import { focusTrap } from 'ember-focus-trap';
import onKey from 'ember-keyboard/modifiers/on-key';
import { and, not, or } from 'ember-truth-helpers';
import { tabbable } from 'tabbable';

import randomId from '../-private/random-id.ts';
import { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import merge from '../helpers/merge.ts';
import mutationObserver from '../modifiers/mutation-observer.ts';
import outsideClickDetector from '../modifiers/outside-click-detector.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import simpleStyle from '../modifiers/simple-style.ts';
import { cascadingMenuKeys } from '../utils/accesibility/index.ts';
import {
  anchorPositionMapping,
  displayMapping
} from '../utils/css-mappings/eui-popover.ts';
import { findPopoverPosition, getElementZIndex } from '../utils/popover/index.ts';
import {
  getTransitionTimings,
  getWaitDuration,
  performOnFrame
} from '../utils/transition.ts';
import EuiPanel from './eui-panel.gts';
import EuiPortal from './eui-portal.gts';

import type { paddingSizeMapping } from '../utils/css-mappings/eui-panel.ts';
import type { EuiPopoverPosition } from '../utils/popover/types';
import type { EmberKeyboardEvent } from 'ember-keyboard/modifiers/on-key';

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
  panelClasses?: string;
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
  button?: Component;
  buttonRef?: (e: HTMLDivElement) => unknown;
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
  panelStyle?: { [i: string]: string };
  panelRef?: (e: HTMLElement | null) => unknown;
  popoverRef?: (e: HTMLElement) => unknown;

  /**
   * when not `false`, the popover will check if this popover is inside another popover and if so. will reposition itself to be inside the other popover
   */
  shouldAccountForOtherPopovers?: boolean;

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
  ariaLabel?: string;
  /**
   * Alternative option to `aria-label` that takes an `id`.
   * Usually takes the `id` of the popover title
   */
  ariaLabelledBy?: string;

  tabindex?: string | number;

  shouldSelfFocus?: boolean;

  isFocusTrapPaused?: boolean;

  focusTrapOptions?: {
    onClickOutside?: (e: Event) => void;
  };

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

export const ANCHOR_POSITIONS = Object.keys(anchorPositionMapping);
export const DISPLAY = Object.keys(displayMapping);
export type FocusTarget = HTMLElement | string | (() => HTMLElement);

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

export interface EuiPopoverSignature {
  Element: HTMLDivElement;
  Args: EuiPopoverArgs;
  Blocks: {
    button: [];
    content: [];
    arrowChildren: [];
  };
}

export default class EuiPopoverComponent extends Component<EuiPopoverSignature> {
  // Defaults
  @argOrDefaultDecorator(false) isOpen!: boolean;
  @argOrDefaultDecorator(true) ownFocus!: boolean;
  @argOrDefaultDecorator('downCenter') anchorPosition!: PopoverAnchorPosition;
  @argOrDefaultDecorator('m') panelPaddingSize!: PanelPaddingSize;
  @argOrDefaultDecorator(true) hasArrow!: boolean;
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
  private hasSetInitialFocus: boolean = false;
  @tracked button: HTMLElement | null = null;
  @tracked panel: HTMLElement | null = null;

  constructor(owner: unknown, args: EuiPopoverArgs) {
    super(owner, args);
    assert(`Must provide closePopover function`, this.args.closePopover);
    this.prevIsOpen = this.isOpen;
    this.suppressingPopover = this.isOpen;
    this.isCurrentlyOpen = this.isOpen;
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

  updateFocus(): void {
    // Wait for the DOM to update.
    this.updateFocusAnimationFrame = window.requestAnimationFrame(() => {
      if (!this.ownFocus || !this.panel || this.args.initialFocus === false) {
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
        250
      );
    }

    this.prevIsOpen = this.args.isOpen;
  }

  willDestroy(): void {
    super.willDestroy();
    window.removeEventListener('scroll', this.positionPopoverFixed, true);
    this.popoverHost = null;
    cancel(this.respositionTimeout as ReturnType<typeof later>);
    cancel(this.closingTransitionTimeout as ReturnType<typeof later>);
    cancelAnimationFrame(this.closingTransitionAnimationFrame as number);
    cancelAnimationFrame(this.updateFocusAnimationFrame as number);
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

    // get the position of the element relative to the offsetParent, which could be the document
    function getPos(ele: HTMLElement): [number, number] {
      let currTop = 0;
      let currLeft = 0;

      if (ele.offsetParent) {
        do {
          currTop += ele.offsetTop;
          currLeft += ele.offsetLeft;
        } while ((ele = ele.offsetParent as HTMLElement));
      } else {
        currTop = ele.offsetTop;
        currLeft = ele.offsetLeft;
      }

      return [currTop, currLeft];
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
      offset:
        !this.args.attachToAnchor && this.hasArrow
          ? 16 + (this.args.offset || 0)
          : 8 + (this.args.offset || 0),
      arrowConfig: {
        arrowWidth: 24,
        arrowBuffer: 10
      },
      returnBoundingBox: this.args.attachToAnchor,
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
      zIndex: `${popoverStyles.zIndex}`
    };
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
    this.button = btn;
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
    {{#let
      (randomId)
      (classNames
        (if this.isOpening "euiPopover-isOpen")
        position=this.anchorPosition
        display=this.display
        componentName="EuiPopover"
      )
      (classNames
        "euiPopover__panel"
        (concat "euiPopover__panel--" this.arrowPosition)
        (if this.isOpening "euiPopover__panel-isOpen")
        (if
          (or (not this.hasArrow) @attachToAnchor) "euiPopover__panel-noArrow"
        )
        (if @attachToAnchor "euiPopover__panel-isAttached")
        @panelClasses
      )
      as |descriptionId classes panelClasses|
    }}
      <div
        class={{classes}}
        {{onKey "_all" this.onKeyDown priority=1}}
        {{didInsert this.didInsertPopover}}
        {{didUpdate this.didUpdateIsOpen @isOpen}}
        {{didUpdate this.didUpdateRepositionOnScroll @repositionOnScroll}}
        {{didInsert (optional @popoverRef)}}
        ...attributes
      >

        {{! button }}
        <div
          class="euiPopover__anchor {{@anchorClassName}}"
          {{didInsert this.registerButton}}
        >
          {{yield to="button"}}
        </div>

        {{! content }}
        {{#if
          (and
            (not this.suppressingPopover)
            (or this.isCurrentlyOpen this.isClosing)
          )
        }}
          <EuiPortal @insert={{this.insert}}>
            {{#let (randomId) as |panelId|}}
              <EuiPanel
                id={{panelId}}
                class={{panelClasses}}
                aria-live={{if this.ownFocus "off" "assertive"}}
                role="dialog"
                aria-label={{@ariaLabel}}
                aria-labelledby={{@ariaLabelledBy}}
                aria-modal="true"
                aria-describedby={{if this.ownFocus descriptionId}}
                tabindex={{this.tabindex}}
                @hasShadow={{false}}
                @paddingSize={{this.panelPaddingSize}}
                {{simpleStyle this._popoverStyles}}
                {{didInsert this.registerPanel}}
                {{outsideClickDetector onOutsideClick=this.onClickOutside}}
                {{onKey "Escape" this.onEscapeKey}}
                {{focusTrap
                  isActive=(not
                    (or
                      (not this.ownFocus) (not this.isOpenStable) this.isClosing
                    )
                  )
                  shouldSelfFocus=this.shouldSelfFocus
                  isPaused=this.isFocusTrapPaused
                  focusTrapOptions=(merge
                    (hash
                      returnFocusOnDeactivate=this.isOpenStable
                      initialFocus=(or @initialFocus this.panel)
                      onDeactivate=(optional @onTrapDeactivation)
                      preventScroll=true
                      clickOutsideDeactivates=true
                      fallbackFocus=(concat "#" panelId)
                    )
                    @focusTrapOptions
                  )
                }}
              >
                <div
                  class={{concat
                    "euiPopover__panelArrow euiPopover__panelArrow--"
                    this.arrowPosition
                  }}
                  style={{this._arrowStyles}}
                >
                  {{yield to="arrowChildren"}}
                </div>
                {{#if this.ownFocus}}
                  <p id={{descriptionId}} {{screenReaderOnly}}>
                    You are in a dialog. To close this dialog, hit escape.
                  </p>
                {{/if}}
                <div
                  {{mutationObserver
                    onMutation=this.onMutation
                    observerOptions=(merge
                      (hash
                        attributes=true
                        childList=true
                        characterData=true
                        subtree=true
                      )
                      @mutationObserverOptions
                    )
                  }}
                >
                  {{yield to="content"}}
                </div>
              </EuiPanel>
            {{/let}}
          </EuiPortal>
        {{/if}}

      </div>
    {{/let}}
  </template>
}
