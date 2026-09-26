import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { throttle } from '@ember/runloop';

import { element } from 'ember-element-helper';
import { focusTrap } from 'ember-focus-trap';
import onKey from 'ember-keyboard/modifiers/on-key';
import { modifier as modBuilder } from 'ember-modifier';
import styleModifier from 'ember-style-modifier/modifiers/style';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import outsideClickDetectorModifier from '../modifiers/outside-click-detector.ts';
import resizeObserverModifier from '../modifiers/resize-observer.ts';
import { isWithinMinBreakpoint } from '../utils/breakpoint.ts';
import { sizeMapping } from '../utils/css-mappings/eui-flyout.ts';
import { keysOf } from './common.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiOverlayMask from './eui-overlay-mask.gts';
import EuiPortal from './eui-portal.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';

export type EuiFlyoutArgs = {
  /** Same as `@closeButtonAriaLabel`. */
  closeAriaLabel?: string;
  /** @deprecated Has no effect: render the flyout only while it is open. */
  isOpen?: boolean;
  /** @deprecated Has no effect, see EuiCollapsibleNav; use `@type="push"`. */
  isDocked?: boolean;
  /** @deprecated Has no effect; use `@pushMinBreakpoint`. */
  dockedBreakpoint?: EuiBreakpointSize | number;
  /** @deprecated Has no effect. */
  showButtonIfDocked?: boolean;

  /** Traps keyboard focus inside the flyout. Defaults to `true`. */
  isFocusTrapActive?: boolean;

  /** Tag of the flyout, e.g. `'nav'` or `'aside'`. Defaults to `'div'`. */
  as?: string;

  /**
   * Width: `'s'`, `'m'` or `'l'`, a number in px or any CSS width.
   * Defaults to `'m'`.
   */
  size?: number | string;

  /** Side of the window it slides in from. Defaults to `'right'`. */
  side?: 'left' | 'right';

  /** `role` of the flyout. Defaults to `'dialog'`. */
  role?: null | string;

  /**
   * Renders a mask over the page behind the flyout, which closes it when
   * clicked. Without it, the page stays usable. Defaults to `true`.
   */
  ownFocus?: boolean;

  /** Clicking outside the flyout calls `@onClose`. Defaults to `false`. */
  outsideClickCloses?: boolean;

  /**
   * Close button `'inside'` the flyout's corner or `'outside'` next to it.
   * Defaults to `'inside'`.
   */
  closeButtonPosition?: 'outside' | 'inside';

  /**
   * Padding of `EuiFlyoutHeader`, `EuiFlyoutBody` and `EuiFlyoutFooter`:
   * `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'l'`.
   */
  paddingSize?: string;

  /** Hides the close button (e.g. when the flyout has its own). */
  hideCloseButton?: boolean;

  /** Props for the close button: `{ className, onClick }`. */
  closeButtonProps?: {
    className?: string;
    onClick?: (e: MouseEvent) => void;
    classes?: string;
  };

  /** Accessible label of the close button, e.g. "Close this dialog". */
  closeButtonAriaLabel?: string;

  /**
   * Called by the close button, Escape, the mask and outside clicks. Stop
   * rendering the flyout here. Without it there is no close button.
   */
  onClose?: () => void;

  /**
   * Caps the width: `true` for EUI's default max width, or a number in px.
   * Defaults to `false`.
   */
  maxWidth?: boolean | number;

  /** @deprecated Has no effect. */
  maskProps?: Record<string, unknown>;

  /**
   * `'overlay'` covers the page; `'push'` pads the page so the flyout sits
   * beside it (on windows at least `@pushMinBreakpoint` wide).
   * Defaults to `'overlay'`.
   */
  type?: string;

  /**
   * Minimum window width for `@type="push"`: a named breakpoint (`'xs'`
   * to `'xl'`) or px. Smaller windows get an overlay. Defaults to `'l'`.
   */
  pushMinBreakpoint?: number | EuiBreakpointSize;

  /** Focuses the flyout itself when it opens. Defaults to `true`. */
  shouldSelfFocus?: boolean;

  /**
   * Options for the focus trap (focus-trap library), e.g.
   * `{ initialFocus: '#name' }`. Defaults to allowing outside clicks.
   */
  focusTrapOptions?: {
    allowOutsideClick?: boolean;
    clickOutsideDeactivates?: boolean;
    initialFocus?: string | HTMLElement | (() => HTMLElement);
    fallbackFocus?: string | HTMLElement | (() => HTMLElement);
    escapeDeactivates?: boolean;
    returnFocusOnDeactivate?: boolean;
    preventScroll?: boolean;
  };
};

const classesModifier = modBuilder(
  (
    _element: Element,
    _pos,
    {
      type,
      isPushed,
      side,
      dimensions = {},
      functionToCallOnWindowResize
    }: {
      type: string;
      isPushed: boolean;
      side: string;
      dimensions?: { width?: number };
      functionToCallOnWindowResize: () => void;
    }
  ) => {
    // This class doesn't actually do anything by EUI, but is nice to add for consumers (JIC)
    document.body.classList.add('euiBody--hasFlyout');

    /**
     * Accomodate for the `isPushed` state by adding padding to the body equal to the width of the element
     */
    if (type === 'push') {
      // Only add the event listener if we'll need to accommodate with padding
      window.addEventListener('resize', functionToCallOnWindowResize);

      if (isPushed && dimensions.width) {
        if (side === 'right') {
          document.body.style.paddingRight = `${dimensions.width}px`;
        } else if (side === 'left') {
          document.body.style.paddingLeft = `${dimensions.width}px`;
        }
      }
    }

    return () => {
      document.body.classList.remove('euiBody--hasFlyout');

      if (type === 'push') {
        window.removeEventListener('resize', functionToCallOnWindowResize);

        if (side === 'right') {
          document.body.style.paddingRight = '';
        } else if (side === 'left') {
          document.body.style.paddingLeft = '';
        }
      }
    };
  }
);

export const SIZES = keysOf(sizeMapping);
export type EuiFlyoutSize = (typeof SIZES)[number];

function isEuiFlyoutSizeNamed(value: any): value is EuiFlyoutSize {
  return SIZES.includes(value);
}

/**
 * A panel sliding in from the side of the window, for details or forms
 * that keep the page context. Render it only while open:
 * `{{#if this.isOpen}}<EuiFlyout @onClose={{…}}>…</EuiFlyout>{{/if}}`.
 */
export interface EuiFlyoutSignature {
  Element: any;
  Args: EuiFlyoutArgs;
  Blocks: {
    /** Usually `EuiFlyoutHeader`, `EuiFlyoutBody` and `EuiFlyoutFooter`. */
    default: [];
  };
}

export default class EuiFlyoutComponent extends Component<EuiFlyoutSignature> {
  @tracked windowIsLargeEnoughToPush = isWithinMinBreakpoint(
    typeof window === 'undefined' ? -Infinity : window.innerWidth,
    this.pushMinBreakpoint
  );

  @tracked dimensions?: { width?: number; height?: number };

  get as() {
    return this.args.as ?? 'div';
  }

  get hideCloseButton() {
    return this.args.hideCloseButton ?? false;
  }

  get closeButtonPosition() {
    return this.args.closeButtonPosition ?? 'inside';
  }

  get ownFocus() {
    return this.args.ownFocus ?? true;
  }

  get side() {
    return this.args.side ?? 'right';
  }

  get size() {
    return this.args.size ?? 'm';
  }

  get paddingSize() {
    return this.args.paddingSize ?? 'l';
  }

  get maxWidth() {
    return this.args.maxWidth ?? false;
  }

  get type() {
    return this.args.type ?? 'overlay';
  }

  get outsideClickCloses() {
    return this.args.outsideClickCloses ?? false;
  }

  get role() {
    return this.args.role ?? 'dialog';
  }

  get pushMinBreakpoint() {
    return this.args.pushMinBreakpoint ?? 'l';
  }

  get isPushed() {
    return this.type === 'push' && this.windowIsLargeEnoughToPush;
  }

  get styles() {
    let newStyle: { [key: string]: unknown } = {};

    if (this.maxWidth !== false) {
      const value =
        typeof this.maxWidth === 'number'
          ? `${this.maxWidth}px`
          : this.maxWidth;

      newStyle = { maxWidth: value };
    }

    if (!isEuiFlyoutSizeNamed(this.size) && newStyle) {
      newStyle['width'] = this.size;
    } else {
      newStyle = { width: this.size };
    }

    return newStyle;
  }

  @action
  functionToCallOnWindowResize() {
    throttle(() => {
      if (isWithinMinBreakpoint(window.innerWidth, this.pushMinBreakpoint)) {
        this.windowIsLargeEnoughToPush = true;
      } else {
        this.windowIsLargeEnoughToPush = false;
      }
    }, 50);
  }

  @action
  onClose() {
    this.args.onClose?.();
  }

  @action
  onButtonCloseClicked(e: MouseEvent) {
    this.onClose();
    this.args.closeButtonProps?.onClick?.(e);
  }

  @action
  onResize(dimensions: { width: number; height: number }) {
    this.dimensions = dimensions;
  }

  <template>
    {{#let
      (classNames
        (if (eq this.maxWidth true) "euiFlyout--maxWidth-default")
        componentName="EuiFlyout"
        type=this.type
        side=this.side
        size=this.size
        padding=this.paddingSize
      )
      (classNames
        "euiFlyout__closeButton"
        (concat "euiFlyout__closeButton--" this.closeButtonPosition)
        (or @closeButtonProps.className @closeButtonProps.classes)
      )
      (modifier
        focusTrap
        isActive=(argOrDefault @isFocusTrapActive true)
        shouldSelfFocus=(argOrDefault @shouldSelfFocus true)
        isPaused=this.isPushed
        focusTrapOptions=(argOrDefault
          @focusTrapOptions
          (hash
            allowOutsideClick=true clickOutsideDeactivates=(not this.ownFocus)
          )
        )
      )
      (modifier
        outsideClickDetectorModifier
        isDisabled=(or this.isPushed (not this.outsideClickCloses))
        onOutsideClick=this.onClose
      )
      (modifier styleModifier this.styles)
      (modifier onKey "Escape" this.onClose)
      (modifier
        classesModifier
        type=this.type
        isPushed=this.isPushed
        side=this.side
        dimensions=this.dimensions
        functionToCallOnWindowResize=this.functionToCallOnWindowResize
      )
      (modifier resizeObserverModifier onResize=this.onResize)
      (element this.as)
      as |classes closeButtonClasses focusTrapModifier outsideClickDetector currentStyles onEscape classesModifier resizeObserver TheElement|
    }}

      {{#if (and this.ownFocus (not this.isPushed))}}
        <EuiOverlayMask @headerZindexLocation="below" @onClick={{this.onClose}}>
          <TheElement
            role={{this.role}}
            class={{classes}}
            tabindex={{-1}}
            {{!@glint-expect-error}}
            {{currentStyles}}
            {{!@glint-expect-error}}
            {{focusTrapModifier}}
            {{outsideClickDetector}}
            {{onEscape}}
            {{classesModifier}}
            {{resizeObserver}}
            ...attributes
          >
            {{#if (and @onClose (not @hideCloseButton))}}
              <EuiButtonIcon
                @display={{if
                  (eq this.closeButtonPosition "outside")
                  "fill"
                  "empty"
                }}
                @iconType="cross"
                @color="text"
                aria-label={{or @closeButtonAriaLabel @closeAriaLabel}}
                data-test-subj="euiFlyoutCloseButton"
                class={{closeButtonClasses}}
                {{on "click" this.onButtonCloseClicked}}
              />
            {{/if}}
            {{yield}}
          </TheElement>
        </EuiOverlayMask>
      {{else if (not this.isPushed)}}
        <EuiPortal>
          <TheElement
            role={{this.role}}
            class={{classes}}
            tabindex={{-1}}
            {{currentStyles}}
            {{!@glint-expect-error}}
            {{focusTrapModifier}}
            {{outsideClickDetector}}
            {{onEscape}}
            {{classesModifier}}
            {{resizeObserver}}
            ...attributes
          >
            {{#if (and @onClose (not @hideCloseButton))}}
              <EuiButtonIcon
                @display={{if
                  (eq this.closeButtonPosition "outside")
                  "fill"
                  "empty"
                }}
                @iconType="cross"
                @color="text"
                aria-label={{or @closeButtonAriaLabel @closeAriaLabel}}
                data-test-subj="euiFlyoutCloseButton"
                class={{closeButtonClasses}}
                {{on "click" this.onButtonCloseClicked}}
              />
            {{/if}}
            {{yield}}
          </TheElement>
        </EuiPortal>
      {{else}}
        <TheElement
          role={{this.role}}
          class={{classes}}
          tabindex={{-1}}
          {{currentStyles}}
          {{!@glint-expect-error}}
          {{focusTrapModifier}}
          {{outsideClickDetector}}
          {{onEscape}}
          {{classesModifier}}
          {{resizeObserver}}
          ...attributes
        >
          {{#if (and @onClose (not @hideCloseButton))}}
            <EuiButtonIcon
              @display={{if
                (eq this.closeButtonPosition "outside")
                "fill"
                "empty"
              }}
              @iconType="cross"
              @color="text"
              aria-label={{or @closeButtonAriaLabel @closeAriaLabel}}
              data-test-subj="euiFlyoutCloseButton"
              class={{closeButtonClasses}}
              {{on "click" this.onButtonCloseClicked}}
            />
          {{/if}}
          {{yield}}
        </TheElement>
      {{/if}}
    {{/let}}
  </template>
}
