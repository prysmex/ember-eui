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
import { modifier } from 'ember-modifier';
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
  closeAriaLabel?: string;
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

  isFocusTrapActive?: boolean;

  as?: string;

  size?: number | string;

  side?: 'left' | 'right';

  role?: null | string;

  ownFocus?: boolean;

  outsideClickCloses?: boolean;

  closeButtonPosition?: 'outside' | 'inside';

  paddingSize?: string;

  hideCloseButton?: boolean;

  closeButtonProps?: {
    className?: string;
    onClick?: (e: MouseEvent) => void;
    classes?: string;
  };

  closeButtonAriaLabel?: string;

  onClose: () => void;

  maxWidth?: boolean | number;

  maskProps?: Record<string, unknown>;

  type?: string;

  pushMinBreakpoint?: number | EuiBreakpointSize;

  shouldSelfFocus?: boolean;

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

const classesModifier = modifier(
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

export interface EuiFlyoutSignature {
  Element: any;
  Args: EuiFlyoutArgs;
  Blocks: {
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
