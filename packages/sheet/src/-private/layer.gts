/**
 * The layer the sheet's floating parts render in (V03 batch 2, after the
 * real-input check): the row menu, the field editor (and its delete
 * confirmation) and the panel editors (select, date, zone pickers).
 * Positioned inside the wrapper, an ancestor's `overflow: hidden` (a card,
 * a panel, a tab) cut them off; now they are portaled to `<body>` and
 * placed with `position: fixed` from their anchor's box in the viewport.
 *
 * The layer carries the sheet's theme class (the `--euiSheet-*` colours),
 * and passes the events the wrapper listens to on to the sheet: they no
 * longer bubble through the wrapper (the editors' keys, the menu's Escape,
 * focus tracking, the long press).
 */
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import EuiPortal from '@ember-eui/core/components/eui-portal';
import { attachToFocusTraps } from '@ember-eui/core/-private/focus-trap-registry';
import { getElementZIndex } from '@ember-eui/core/utils/popover/index';

import type EuiSheet from '../components/eui-sheet.gts';

/** A box in the viewport, in px (`getBoundingClientRect()`'s space). */
export interface LayerAnchor {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/** Marks a layer; its value is the sheet's id. */
export const LAYER_SELECTOR = '[data-eui-sheet-layer]';

/** Kept free between a layer and the viewport's edges. */
const VIEWPORT_MARGIN = 8;

interface SheetLayerSignature {
  Args: { sheet: EuiSheet<any> };
  Blocks: { default: [] };
}

/**
 * The `--euiSheet-*` overrides set on the sheet itself (its `style`
 * attribute), copied when the layer opens: the layer is not inside the
 * wrapper, so it does not inherit them.
 */
const copyOverrides = modifier(
  (element: HTMLElement, [wrapper]: [HTMLElement | null]) => {
    const style = wrapper?.style;
    if (!style) return;
    for (let i = 0; i < style.length; i++) {
      const name = style.item(i);
      if (name.startsWith('--euiSheet-')) {
        element.style.setProperty(name, style.getPropertyValue(name));
      }
    }
  }
);

/** The portal, the theme class, the wrapper's overrides and listeners. */
export default class SheetLayer extends Component<SheetLayerSignature> {
  leaveFocusTraps: (() => void) | null = null;

  /**
   * A focus trap around the sheet (a modal, an own-focus flyout) takes the
   * portal in, as it does EUI's own portaled popovers, before the content
   * renders: an editor focuses its input as it renders, and a trap that
   * does not know the portal yet pulls focus back.
   */
  joinFocusTraps = (portal: HTMLElement): void => {
    this.leaveFocusTraps = attachToFocusTraps(this.args.sheet.wrapper, portal);
  };

  willDestroy(): void {
    super.willDestroy();
    this.leaveFocusTraps?.();
  }

  <template>
    <EuiPortal @portalRef={{this.joinFocusTraps}}>
      <div
        class="euiSheetLayer {{@sheet.themeClass}}"
        data-eui-sheet-layer={{@sheet.sheetId}}
        {{copyOverrides @sheet.wrapper}}
        {{on "keydown" @sheet.onKeyDown capture=true}}
        {{on "mousedown" @sheet.drag.onMouseDown capture=true}}
        {{on "pointerdown" @sheet.touch.onPointerDown capture=true}}
        {{on "pointermove" @sheet.touch.onPointerMove}}
        {{on "pointerup" @sheet.touch.onPointerEnd}}
        {{on "pointercancel" @sheet.touch.onPointerEnd}}
        {{on "click" @sheet.touch.onClickCapture capture=true}}
        {{on "focusin" @sheet.focus.onFocusIn}}
        {{on "focusout" @sheet.focus.onFocusOut}}
        {{on "click" @sheet.clicks.onClick}}
        {{on "contextmenu" @sheet.rowMenu.onContextMenu}}
      >
        {{yield}}
      </div>
    </EuiPortal>
  </template>
}

export interface PlaceLayerOptions {
  /** The anchor's box now, in the viewport; read at every placement. */
  anchor: () => LayerAnchor | null;
  /** The sheet's wrapper: the layer stacks above its stacking context. */
  wrapper?: HTMLElement | null;
  /** px between the anchor and the layer. */
  gap?: number;
  /** The part that scrolls once the layer is clamped (it gets `--euiSheetLayerMaxHeight`). */
  scroller?: string;
  /** The clamp never makes the layer shorter than this. */
  minHeight?: number;
  /** The layer's least width. */
  minWidth?: number;
  /**
   * Anything that moves the anchor (the editor's cell box after a grid
   * scroll): a change places the layer again.
   */
  watch?: unknown;
}

type Placement = 'below' | 'above';

/**
 * Places a layer under its anchor, or above it when it does not fit below
 * and fits (or has more room) above; clamped to the viewport horizontally;
 * with a `scroller`, its height is clamped to the room on that side (at
 * least `minHeight`) and the part scrolls. Placed again on a scroll of the
 * page or of any ancestor, a resize of the window, and a change of the
 * layer's size (its content grew); a placement that still fits is kept.
 */
export const placeLayer = modifier(
  (element: HTMLElement, _: unknown[], options: PlaceLayerOptions) => {
    // a change of the anchor's box re-runs the modifier
    void options.watch;
    let placement: Placement | null = null;
    const gap = options.gap ?? 0;
    element.style.zIndex = String(
      (options.wrapper ? getElementZIndex(options.wrapper, element) : 0) + 2000
    );
    if (options.minWidth !== undefined) {
      element.style.minWidth = `${options.minWidth}px`;
    }

    const place = (): void => {
      const anchor = options.anchor();
      if (!anchor || !element.isConnected) return;
      const viewport = document.documentElement;
      const width = viewport.clientWidth || window.innerWidth;
      const height = viewport.clientHeight || window.innerHeight;
      const part = options.scroller
        ? element.querySelector<HTMLElement>(options.scroller)
        : null;
      // the height the content wants: the layer's, plus what the scrolling
      // part hides now
      const natural =
        element.offsetHeight +
        (part ? part.scrollHeight - part.clientHeight : 0);
      const room: Record<Placement, number> = {
        below: height - anchor.bottom - gap - VIEWPORT_MARGIN,
        above: anchor.top - gap - VIEWPORT_MARGIN
      };
      const fits = (side: Placement) => natural <= room[side];
      if (!placement || !fits(placement)) {
        placement = fits('below')
          ? 'below'
          : fits('above')
            ? 'above'
            : room.above > room.below
              ? 'above'
              : 'below';
      }
      if (part) {
        const chrome = element.offsetHeight - part.offsetHeight;
        const max = Math.max(room[placement], options.minHeight ?? 0) - chrome;
        part.style.setProperty(
          '--euiSheetLayerMaxHeight',
          `${Math.floor(max)}px`
        );
      }
      const box = element.getBoundingClientRect();
      const left = Math.max(
        VIEWPORT_MARGIN,
        Math.min(anchor.left, width - VIEWPORT_MARGIN - box.width)
      );
      element.style.left = `${Math.round(left)}px`;
      element.dataset['placement'] = placement;
      const edge =
        placement === 'below' ? anchor.bottom + gap : anchor.top - gap;
      // taller than the room (the least height): kept in the viewport
      const top = Math.max(
        VIEWPORT_MARGIN,
        Math.min(
          placement === 'below' ? edge : edge - box.height,
          height - VIEWPORT_MARGIN - box.height
        )
      );
      if (placement === 'above' && top === edge - box.height) {
        // above: its bottom edge is fixed at the anchor, so content that
        // grows or shrinks (a list being filtered) keeps it attached
        element.style.top = 'auto';
        element.style.bottom = `${Math.round(height - edge)}px`;
      } else {
        element.style.bottom = 'auto';
        element.style.top = `${Math.round(top)}px`;
      }
    };

    place();

    // a scroll of the page or an ancestor moves the anchor; the layer's
    // own scrolling (its list, its form) does not
    const onScroll = (event: Event): void => {
      const target = event.target;
      if (target instanceof Node && element.contains(target)) return;
      place();
    };
    document.addEventListener('scroll', onScroll, true);
    window.addEventListener('resize', place);
    // a size change is placed in the next frame: placing changes the
    // size, which inside the observer's callback is a resize loop
    let frame = 0;
    const onResize = (): void => {
      if (frame) return;
      frame = requestAnimationFrame(() => {
        frame = 0;
        place();
      });
    };
    const observer =
      typeof ResizeObserver === 'function'
        ? new ResizeObserver(onResize)
        : null;
    if (observer) {
      observer.observe(element);
      const content = options.scroller
        ? element.querySelector(options.scroller)?.firstElementChild
        : null;
      if (content) observer.observe(content);
    }
    return () => {
      document.removeEventListener('scroll', onScroll, true);
      window.removeEventListener('resize', place);
      observer?.disconnect();
      if (frame) cancelAnimationFrame(frame);
    };
  }
);
