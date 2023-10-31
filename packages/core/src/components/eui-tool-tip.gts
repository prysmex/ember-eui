import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { guidFor } from "@ember/object/internals";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-insert";
import { cancel, later, next, scheduleOnce } from "@ember/runloop";
import resizeObserver from "../modifiers/resize-observer";

import { and, eq, or } from "ember-truth-helpers";

import argOrDefault, { argOrDefaultDecorator } from "../helpers/arg-or-default";
import classNames from "../helpers/class-names";
import { keys } from "../utils/keys";
import { findPopoverPosition } from "../utils/popover";
import EuiPortal from "./eui-portal";
import EuiToolTipPopover from "./eui-tool-tip-popover";
import type { EuiTooltipPopoverSignature } from "./eui-tool-tip-popover";
import { on } from "@ember/modifier";
import style from "ember-style-modifier/modifiers/style";

export type ToolTipPositions = "top" | "right" | "bottom" | "left";

export type ToolTipDelay = "regular" | "long";

const delayToMsMap: { [key in ToolTipDelay]: number } = {
  regular: 250,
  long: 250 * 5,
};

interface ToolTipStyles {
  top: string;
  left: string | "auto";
  right?: string | "auto";
  opacity?: string;
  visibility?: "hidden";
  display?: "inlineBlock";
}

const displayToClassNameMap = {
  inlineBlock: undefined,
  block: "euiToolTipAnchor--displayBlock",
};

const DEFAULT_TOOLTIP_STYLES: ToolTipStyles = {
  // position the tooltip content near the top-left
  // corner of the window so it can't create scrollbars
  // 50,50 because who knows what negative margins, padding, etc
  top: "50px",
  left: "50px",
  // just in case, avoid any potential flicker by hiding
  // the tooltip before it is positioned
  opacity: "0",
  // prevent accidental mouse interaction while positioning
  visibility: "hidden",
  display: "inlineBlock",
};

export type EuiTooltipArgs = {
  /**
   * Passes onto the the trigger.
   */
  anchorClassName?: string;
  /**
   * Passes onto the tooltip itself, not the trigger.
   */
  className?: string;
  /**
   * The main content of your tooltip.
   */
  content?: string;
  /**
   * Common display alternatives for the anchor wrapper
   */
  display?: keyof typeof displayToClassNameMap;
  /**
   * Delay before showing tooltip. Good for repeatable items.
   */
  delay?: ToolTipDelay;
  /**
   * An optional title for your tooltip.
   */
  title?: string;
  /**
   * Unless you provide one, this will be randomly generated.
   */
  id?: string;
  /**
   * Suggested position. If there is not enough room for it this will be changed.
   */
  position?: ToolTipPositions;

  attachTo?: undefined | HTMLElement | string | null;

  isShown?: boolean | undefined;

  /**
   * If supplied, called when mouse movement causes the tool tip to be
   * hidden.
   */
  onMouseOut?: (event: MouseEvent) => void;
  onFocus?: () => void;
  onBlur?: () => void;

  hasTitle?: boolean;
};

export interface EuiToolTipSignature {
  Element: EuiTooltipPopoverSignature["Element"];
  Args: EuiTooltipArgs;
  Blocks: {
    default?: [id: string];
    title?: [];
    content?: [];
    anchor?: [id: string];
  };
}

export default class EuiToolTip extends Component<EuiToolTipSignature> {
  anchor: null | HTMLElement = null;
  popover: null | HTMLElement = null;

  @argOrDefaultDecorator("top") position!: ToolTipPositions;
  @argOrDefaultDecorator("regular") delay!: ToolTipDelay;

  //STATE
  @tracked visible = false;
  @tracked hasFocus = false;
  @tracked calculatedPosition: ToolTipPositions = this.position;
  @tracked toolTipStyles: ToolTipStyles = DEFAULT_TOOLTIP_STYLES;
  @tracked arrowStyles: { left?: string; top?: string } = {};
  @tracked id: string = this.args.id || guidFor({});
  @tracked _attachTo: undefined | HTMLElement | string | null = null;

  private timeoutId?: ReturnType<typeof later>;

  @action
  updateAttachTo(): void {
    if (!this.args.attachTo && this._attachTo) {
      this.removeAttachToHandlers();
      this._attachTo = null;
      return;
    }

    if (this.args.attachTo && this.args.attachTo !== this._attachTo) {
      next(() => {
        this.removeAttachToHandlers();
        this._attachTo = this.args.attachTo;
        this.setupAttachToHandlers();
      });
    }
  }

  @action
  setupAttachToHandlers(): void {
    if (this._attachTo && this.attachTo) {
      this.attachTo.addEventListener("mousemove", this.showToolTip);
      this.attachTo.addEventListener("focusin", this.onFocus);
      //@ts-expect-error
      this.attachTo.addEventListener("mouseout", this.onMouseOut);
      this.attachTo.addEventListener("focusout", this.onBlur);
      this.positionToolTip();
    }
  }

  @action
  removeAttachToHandlers(): void {
    if (this._attachTo && this.attachTo) {
      this.attachTo.removeEventListener("mousemove", this.showToolTip);
      this.attachTo.removeEventListener("focusin", this.onFocus);
      //@ts-expect-error
      this.attachTo.removeEventListener("mouseout", this.onMouseOut);
      this.attachTo.removeEventListener("focusout", this.onBlur);
    }
  }

  @action
  clearAnimationTimeout(): void {
    if (this.timeoutId) {
      cancel(this.timeoutId);
      this.timeoutId = undefined;
    }
  }

  @action
  visibleDidUpdate(value: boolean): void {
    if (this.visible === false && value === true) {
      requestAnimationFrame(this.testAnchor);
    }
  }

  willDestroy(): void {
    super.willDestroy();
    this.clearAnimationTimeout();
    this.removeAttachToHandlers();
  }

  @action
  testAnchor(): void {
    // when the tooltip is visible, this checks if the anchor is still part of document
    // this fixes when the react root is removed from the dom without unmounting
    // https://github.com/elastic/eui/issues/1105
    if (document.body.contains(this._anchor) === false) {
      // the anchor is no longer part of `document`
      this.hideToolTip();
    } else {
      if (this.visible) {
        // if still visible, keep checking
        requestAnimationFrame(this.testAnchor);
      }
    }
  }

  @action
  didInsertAnchor(ref: HTMLElement): void {
    this.anchor = ref;
  }

  @action
  setPopoverRef(ref: HTMLElement | null): void {
    this.popover = ref;

    // if the popover has been unmounted, clear
    // any previous knowledge about its size
    if (ref === null) {
      this.toolTipStyles = DEFAULT_TOOLTIP_STYLES;
      this.arrowStyles = {};
    } else {
      this.positionToolTip();
    }
  }

  @action
  showToolTip(): void {
    if (!this.timeoutId && !this.visible) {
      const fn = (): void => {
        this.visible = true;
      };
      this.timeoutId = later(
        this,
        () => {
          scheduleOnce("afterRender", this, fn);
        },
        delayToMsMap[this.delay],
      );
    }
  }

  @cached
  get attachTo(): Element | null | undefined {
    if (typeof this._attachTo === "string") {
      return document.querySelector(this._attachTo);
    } else {
      return this._attachTo;
    }
  }

  get _anchor(): Element | null {
    return this.attachTo || this.anchor;
  }

  @action
  positionToolTip(): void {
    const requestedPosition = this.position;

    if (!this._anchor || !this.popover) {
      return;
    }
    const { position, left, top, arrow } = findPopoverPosition({
      anchor: this._anchor as HTMLElement,
      popover: this.popover,
      position: requestedPosition,
      offset: 16, // offset popover 16px from the anchor
      arrowConfig: {
        arrowWidth: 12,
        arrowBuffer: 4,
      },
    });

    const windowWidth =
      document.documentElement.clientWidth || window.innerWidth;
    const useRightValue = windowWidth / 2 < left;

    const toolTipStyles: ToolTipStyles = {
      top: `${top}px`,
      left: useRightValue ? "auto" : `${left}px`,
      right: useRightValue
        ? `${windowWidth - left - this.popover.offsetWidth}px`
        : "auto",
    };

    this.visible = true;
    this.calculatedPosition = position;
    this.toolTipStyles = toolTipStyles;
    if (arrow) {
      this.arrowStyles = {
        left: `${arrow.left}px`,
        top: `${arrow?.top}px`,
      };
    }
  }

  @action
  hideToolTip(): void {
    if (this.args.isShown === true) {
      return;
    }
    this.clearAnimationTimeout();
    const fn = (): void => {
      if (!this.isDestroying || !this.isDestroyed) {
        this.visible = false;
      }
    };
    scheduleOnce("afterRender", this, fn);
  }

  @action
  hasFocusMouseMoveListener(): void {
    this.hideToolTip();
    window.removeEventListener("mousemove", this.hasFocusMouseMoveListener);
  }

  @action
  onKeyUp(event: KeyboardEvent): void {
    if (event.key === keys.TAB) {
      window.addEventListener("mousemove", this.hasFocusMouseMoveListener);
    }
  }

  @action
  onFocus(): void {
    this.hasFocus = true;
    this.showToolTip();
  }

  @action
  onBlur(): void {
    this.hasFocus = false;
    this.hideToolTip();
  }

  @action
  onMouseOut(event: MouseEvent): void {
    // Prevent mousing over children from hiding the tooltip by testing for whether the mouse has
    // left the anchor for a non-child.
    if (
      this._anchor === event.relatedTarget ||
      (this._anchor != null &&
        !this._anchor.contains(event.relatedTarget as Node))
    ) {
      if (!this.hasFocus) {
        this.hideToolTip();
      }
    }

    if (this.args.onMouseOut) {
      this.args.onMouseOut(event);
    }
  }

  <template>
    {{#let
      (has-block "content") (has-block "title") (has-block "anchor")
      as |hasContentBlock hasTitleBlock hasAnchorBlock|
    }}
      {{#if @attachTo}}
        <span
          {{didInsert this.updateAttachTo}}
          {{didUpdate this.updateAttachTo @attachTo}}
          {{didUpdate
            (if (eq @isShown true) this.onFocus this.onBlur)
            @isShown
          }}
          {{didInsert (if (eq @isShown true) this.onFocus this.onBlur)}}
        ></span>
      {{else}}
        <span
          role="tooltip"
          class={{classNames
            "euiToolTipAnchor"
            (if (eq @display "block") "euiToolTipAnchor--displayBlock")
            @anchorClassName
          }}
          {{didInsert this.didInsertAnchor}}
          {{on "mouseover" this.showToolTip}}
          {{on "focusin" this.onFocus}}
          {{on "focusout" this.onBlur}}
          {{on "mouseout" this.onMouseOut}}
          {{didUpdate
            (if (eq @isShown true) this.onFocus this.onBlur)
            @isShown
          }}
          {{didInsert (if (eq @isShown true) this.onFocus this.onBlur)}}
        >
          {{#if hasAnchorBlock}}
            {{yield this.id to="anchor"}}
          {{else}}
            {{yield this.id}}
          {{/if}}
        </span>
      {{/if}}
      {{#if
        (and this.visible (or @title @content hasContentBlock hasTitleBlock))
      }}
        <EuiPortal>
          <EuiToolTipPopover
            class={{classNames
              "euiToolTip"
              componentName="EuiToolTip"
              position=this.calculatedPosition
            }}
            @positionToolTip={{this.positionToolTip}}
            @popoverRef={{this.setPopoverRef}}
            id={{this.id}}
            @hasTitle={{if
              (and (argOrDefault @hasTitle true) (or hasTitleBlock @title))
              true
            }}
            role="tooltip"
            ...attributes
            {{style this.toolTipStyles}}
          >
            <:title>
              {{#if hasTitleBlock}}
                {{yield to="title"}}
              {{else}}
                {{@title}}
              {{/if}}
            </:title>
            <:content>
              <div class="euiToolTip__arrow" {{style this.arrowStyles}}></div>
              <div {{resizeObserver onResize=this.positionToolTip}}>
                {{#if hasContentBlock}}
                  {{yield to="content"}}
                {{else}}
                  {{@content}}
                {{/if}}
              </div>
            </:content>
          </EuiToolTipPopover>
        </EuiPortal>
      {{/if}}
    {{/let}}
  </template>
}
