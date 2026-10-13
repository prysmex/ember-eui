import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { cancel, later, next, scheduleOnce } from '@ember/runloop';
import type { SafeString } from '@ember/template';

import { modifier } from 'ember-modifier';
import style from 'ember-style-modifier/modifiers/style';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiToolTipAnchorStyles,
  euiToolTipStyles
} from '../utils/eui/styles.generated.ts';
import { keys } from '../utils/keys.ts';
import { findPopoverPosition, getElementZIndex } from '../utils/popover/index.ts';
import EuiPortal from './eui-portal.gts';
import EuiToolTipPopover from './eui-tool-tip-popover.gts';

import type { EuiTooltipPopoverSignature } from './eui-tool-tip-popover';

export type ToolTipPositions = 'top' | 'right' | 'bottom' | 'left';

export type ToolTipDelay = 'regular' | 'long';

const delayToMsMap: { [key in ToolTipDelay]: number } = {
  regular: 250,
  long: 250 * 5
};

interface ToolTipStyles {
  top: string;
  left: string | 'auto';
  right?: string | 'auto';
  opacity?: string;
  visibility?: 'hidden';
  zIndex?: string;
}

type EuiToolTipDisplay = 'inlineBlock' | 'block' | 'flex';

/** Upstream default distance between the anchor and the tooltip. */
export const DEFAULT_TOOLTIP_OFFSET = 16;

/** A tooltip shown right after another closes skips the fade in (upstream). */
const SKIP_ANIMATION_WINDOW = 250;

/**
 * Upstream `toolTipManager`: one tooltip is visible at a time, and a
 * tooltip replacing another (or shown right after one closed) appears
 * without the entry animation.
 */
class ToolTipManager {
  toolTipsToHide = new Set<() => void>();
  lastHiddenAt: number | null = null;

  registerTooltip(hideCallback: () => void): { skipAnimation: boolean } | null {
    if (this.toolTipsToHide.has(hideCallback)) return null;

    const hadOpen = this.toolTipsToHide.size > 0;
    const recentlyClosed =
      this.lastHiddenAt !== null &&
      Date.now() - this.lastHiddenAt < SKIP_ANIMATION_WINDOW;

    this.toolTipsToHide.forEach((hide) => hide());
    this.toolTipsToHide.clear();
    this.toolTipsToHide.add(hideCallback);

    return { skipAnimation: hadOpen || recentlyClosed };
  }

  deregisterToolTip(hideCallback: () => void): void {
    if (this.toolTipsToHide.delete(hideCallback)) this.lastHiddenAt = Date.now();
  }
}

export const toolTipManager = new ToolTipManager();

/**
 * Upstream links the anchor's child to the visible tooltip with
 * `aria-describedby` (the tooltip id first, existing ids kept). Only the id
 * added here is removed again.
 */
const describedBy = modifier(
  (
    anchor: HTMLElement,
    [target, id, isVisible]: [Element | null | undefined, string, boolean]
  ) => {
    const element = target ?? anchor.firstElementChild;

    if (!element || !isVisible) return;

    const current = (element.getAttribute('aria-describedby') ?? '')
      .split(/\s+/)
      .filter(Boolean);

    if (current.includes(id)) return;

    element.setAttribute('aria-describedby', [id, ...current].join(' '));

    return () => {
      const remaining = (element.getAttribute('aria-describedby') ?? '')
        .split(/\s+/)
        .filter((token) => token && token !== id);

      if (remaining.length) {
        element.setAttribute('aria-describedby', remaining.join(' '));
      } else {
        element.removeAttribute('aria-describedby');
      }
    };
  }
);

const DEFAULT_TOOLTIP_STYLES: ToolTipStyles = {
  // position the tooltip content near the top-left
  // corner of the window so it can't create scrollbars
  // 50,50 because who knows what negative margins, padding, etc
  top: '50px',
  left: '50px',
  // just in case, avoid any potential flicker by hiding
  // the tooltip before it is positioned
  opacity: '0',
  // prevent accidental mouse interaction while positioning
  visibility: 'hidden'
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
   * Display of the anchor wrapper: `'inlineBlock'`, `'block'` or `'flex'`.
   * Defaults to `'inlineBlock'`.
   */
  display?: EuiToolTipDisplay;
  /**
   * Distance between the anchor and the tooltip. Defaults to `16`.
   */
  offset?: number;
  /**
   * Keeps the tooltip visual only: the anchor's element is not linked to
   * it with `aria-describedby`, and Escape does not stop propagating.
   * Use when the anchor's label already says the same. Defaults to `false`.
   */
  disableScreenReaderOutput?: boolean;
  /**
   * Delay before showing: `'regular'` (250ms) or `'long'` (for
   * repeated items). Defaults to `'regular'`.
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
   * Suggested position: `'top'`, `'right'`, `'bottom'` or `'left'`. If
   * there is not enough room for it this will be changed. Defaults to
   * `'top'`.
   */
  position?: ToolTipPositions;

  /**
   * Shows the tooltip for another element (or selector) instead of the
   * `<:anchor>` block's content.
   */
  attachTo?: undefined | HTMLElement | string | null;

  /**
   * Repositions the tooltip when any scrollable ancestor (or the window)
   * scrolls. Needed for fixed-position anchors or a tooltip inside a
   * scrollable container. Defaults to `false`.
   */
  repositionOnScroll?: boolean;

  /** Shows (`true`) or hides (`false`) the tooltip from outside. */
  isShown?: boolean | undefined;

  /**
   * If supplied, called when mouse movement causes the tool tip to be
   * hidden.
   */
  onMouseOut?: (event: MouseEvent) => void;
  /** Called when the anchor gets focus. */
  onFocus?: () => void;
  /** Called when the anchor loses focus. */
  onBlur?: () => void;

  /** Render the title. Defaults to `true`. */
  hasTitle?: boolean;
  /**
   * Extra styles composed last into the tooltip's class (like upstream's
   * `css` prop). Prefer this to `@className` for styles.
   */
  css?: EuiCss;
  /**
   * Extra styles composed last into the anchor wrapper's class (like
   * upstream's `anchorProps.css`). Prefer this to `@anchorClassName` for
   * styles.
   */
  anchorCss?: EuiCss;
  /**
   * Inline style of the anchor wrapper (upstream's `anchorProps.style`),
   * a style string or a safe string.
   */
  anchorStyle?: string | SafeString;
};

/**
 * A short hint shown on hover or focus of its anchor. Keep the content
 * short and non-essential; it is not reachable on touch screens.
 */
export interface EuiToolTipSignature {
  Element: EuiTooltipPopoverSignature['Element'];
  Args: EuiTooltipArgs;
  Blocks: {
    /** Same as `<:anchor>`. */
    default?: [id: string];
    /** The title, instead of `@title`. */
    title?: [];
    /** The content, instead of `@content`. */
    content?: [];
    /**
     * The element the tooltip is for (hover/focus shows it); yields the
     * tooltip's id for `aria-describedby`.
     */
    anchor?: [id: string];
  };
}

export default class EuiToolTip extends Component<EuiToolTipSignature> {
  anchor: null | HTMLElement = null;
  popover: null | HTMLElement = null;

  @argOrDefaultDecorator('top') position!: ToolTipPositions;
  @argOrDefaultDecorator('regular') delay!: ToolTipDelay;

  //STATE
  @tracked visible = false;
  @tracked hasFocus = false;
  @tracked calculatedPosition: ToolTipPositions = this.position;
  @tracked toolTipStyles: ToolTipStyles = DEFAULT_TOOLTIP_STYLES;
  @tracked arrowStyles: { left?: string; top?: string } = {};
  @tracked skipAnimation = false;
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
      this.attachTo.addEventListener('mousemove', this.showToolTip);
      this.attachTo.addEventListener('focusin', this.onFocus);
      //@ts-expect-error
      this.attachTo.addEventListener('mouseout', this.onMouseOut);
      this.attachTo.addEventListener('focusout', this.onBlur);
      this.positionToolTip();
    }
  }

  @action
  removeAttachToHandlers(): void {
    if (this._attachTo && this.attachTo) {
      this.attachTo.removeEventListener('mousemove', this.showToolTip);
      this.attachTo.removeEventListener('focusin', this.onFocus);
      //@ts-expect-error
      this.attachTo.removeEventListener('mouseout', this.onMouseOut);
      this.attachTo.removeEventListener('focusout', this.onBlur);
    }
  }

  private listeningToScroll = false;

  /** Adds or removes the capturing scroll listener (`@repositionOnScroll`). */
  @action
  syncScrollListener(): void {
    const wanted = this.args.repositionOnScroll === true;

    if (wanted && !this.listeningToScroll) {
      window.addEventListener('scroll', this.positionToolTip, true);
    } else if (!wanted && this.listeningToScroll) {
      window.removeEventListener('scroll', this.positionToolTip, true);
    }

    this.listeningToScroll = wanted;
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
        this.markVisible();
      };

      this.timeoutId = later(
        this,
        () => {
          scheduleOnce('afterRender', this, fn);
        },
        delayToMsMap[this.delay]
      );
    }
  }

  /** Shows the tooltip through the manager (hides any other one). */
  markVisible(): void {
    if (this.isDestroying || this.isDestroyed) return;

    const result = toolTipManager.registerTooltip(this.hideToolTip);

    if (result) this.skipAnimation = result.skipAnimation;

    this.visible = true;
  }

  get anchorDisplay(): EuiToolTipDisplay {
    return this.args.display ?? 'inlineBlock';
  }

  /** Upstream `euiToolTipAnchorStyles`: display and disabled children. */
  @cached
  get anchorClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiToolTipAnchorStyles);

    return `euiToolTipAnchor ${euiClass(
      context,
      styles.euiToolTipAnchor,
      styles[this.anchorDisplay] ?? styles.inlineBlock,
      this.args.anchorCss
    )}`;
  }

  @cached
  get arrowClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiToolTipStyles);

    return `euiToolTip__arrow ${euiClass(
      context,
      styles.euiToolTip__arrow,
      styles.arrowPositions[this.calculatedPosition]
    )}`;
  }

  get popoverStyles(): ToolTipStyles & { animation?: string } {
    // inline `animation: none` overrides the fade in (upstream)
    return this.skipAnimation
      ? { ...this.toolTipStyles, animation: 'none' }
      : this.toolTipStyles;
  }

  get describesAnchor(): boolean {
    return this.visible && !this.args.disableScreenReaderOutput;
  }

  @cached
  get attachTo(): Element | null | undefined {
    if (typeof this._attachTo === 'string') {
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
      offset: this.args.offset ?? DEFAULT_TOOLTIP_OFFSET,
      // upstream: the arrow stays out of the control-radius corners
      arrowConfig: {
        arrowWidth: 12,
        arrowBuffer: 4,
        borderRadius:
          parseFloat(
            String(getEuiThemeContext(this).upstream.euiTheme.border.radius.control)
          ) || undefined
      }
    });

    const windowWidth =
      document.documentElement.clientWidth || window.innerWidth;
    const useRightValue = windowWidth / 2 < left;

    const toolTipStyles: ToolTipStyles = {
      top: `${top}px`,
      left: useRightValue ? 'auto' : `${left}px`,
      right: useRightValue
        ? `${windowWidth - left - this.popover.offsetWidth}px`
        : 'auto'
    };

    // Upstream's tooltip stays at `levels.toast`; an anchor inside a layer
    // stacked higher (e.g. an options list or popover in a modal) would hide
    // it, so never stack below the anchor.
    const { levels } = getEuiThemeContext(this).upstream.euiTheme;
    const anchorZIndex = getElementZIndex(
      this._anchor as HTMLElement,
      this.popover
    );
    if (anchorZIndex >= Number(levels.toast)) {
      toolTipStyles.zIndex = String(anchorZIndex + 1);
    }

    if (!this.visible) this.markVisible();
    this.calculatedPosition = position;
    this.toolTipStyles = toolTipStyles;

    if (arrow) {
      this.arrowStyles = {
        left: `${arrow.left}px`,
        top: `${arrow?.top}px`
      };
    }
  }

  @action
  hideToolTip(): void {
    if (this.args.isShown === true) {
      return;
    }

    this.clearAnimationTimeout();

    toolTipManager.deregisterToolTip(this.hideToolTip);

    const fn = (): void => {
      if (!this.isDestroying && !this.isDestroyed) {
        this.visible = false;
      }
    };

    scheduleOnce('afterRender', this, fn);
  }

  /** Escape hides the tooltip (upstream). */
  @action
  onKeyDown(event: KeyboardEvent): void {
    if (event.key !== keys.ESCAPE) return;

    // a visual-only tooltip does not take the Escape key from the page
    if (!this.args.disableScreenReaderOutput && this.visible) {
      event.stopPropagation();
    }

    this.hasFocus = false;
    this.hideToolTip();
  }

  @action
  hasFocusMouseMoveListener(): void {
    this.hideToolTip();
    window.removeEventListener('mousemove', this.hasFocusMouseMoveListener);
  }

  @action
  onKeyUp(event: KeyboardEvent): void {
    if (event.key === keys.TAB) {
      window.addEventListener('mousemove', this.hasFocusMouseMoveListener);
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

  willDestroy(): void {
    super.willDestroy();

    this.clearAnimationTimeout();
    toolTipManager.deregisterToolTip(this.hideToolTip);
    this.removeAttachToHandlers();
    window.removeEventListener('scroll', this.positionToolTip, true);
    this.listeningToScroll = false;
    this.anchor = null;
    this.popover = null;
    this._attachTo = null;
  }

  <template>
    {{#let
      (has-block "content") (has-block "title") (has-block "anchor")
      as |hasContentBlock hasTitleBlock hasAnchorBlock|
    }}
      {{#if @attachTo}}
        <span
          {{didInsert this.updateAttachTo}}
          {{didInsert this.syncScrollListener}}
          {{didUpdate this.syncScrollListener @repositionOnScroll}}
          {{didUpdate this.updateAttachTo @attachTo}}
          {{describedBy this.attachTo this.id this.describesAnchor}}
          {{didUpdate
            (if (eq @isShown true) this.onFocus this.onBlur)
            @isShown
          }}
          {{didInsert (if (eq @isShown true) this.onFocus this.onBlur)}}
        ></span>
      {{else}}
        {{! A11y: NVDA merges identical markup into one stop; the id keeps
            wrappers apart (upstream) }}
        <span
          id={{if (not @disableScreenReaderOutput) (concat this.id "-wrapper")}}
          class={{classNames this.anchorClasses @anchorClassName}}
          style={{@anchorStyle}}
          {{didInsert this.didInsertAnchor}}
          {{didInsert this.syncScrollListener}}
          {{didUpdate this.syncScrollListener @repositionOnScroll}}
          {{describedBy null this.id this.describesAnchor}}
          {{on "keydown" this.onKeyDown}}
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
            class={{classNames "euiToolTip" @className}}
            @calculatedPosition={{this.calculatedPosition}}
            @positionToolTip={{this.positionToolTip}}
            @popoverRef={{this.setPopoverRef}}
            @css={{@css}}
            id={{this.id}}
            @hasTitle={{if
              (and (argOrDefault @hasTitle true) (or hasTitleBlock @title))
              true
            }}
            role="tooltip"
            ...attributes
            {{style this.popoverStyles}}
          >
            <:title>
              {{#if hasTitleBlock}}
                {{yield to="title"}}
              {{else}}
                {{@title}}
              {{/if}}
            </:title>
            <:content>
              <div
                class={{this.arrowClasses}}
                {{style this.arrowStyles}}
              ></div>
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
