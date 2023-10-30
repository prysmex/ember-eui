import Component from '@glimmer/component';
import type { EuiBreakpointSize } from '../utils/breakpoint';
import { tracked } from '@glimmer/tracking';
import { isWithinMinBreakpoint } from '../utils/breakpoint';
import { throttle } from '@ember/runloop';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import { keysOf } from './common';
import { sizeMapping } from '../utils/css-mappings/eui-flyout';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { concat } from '@ember/helper';
import EuiButtonIcon from './eui-button-icon';
import EuiPortal from './eui-portal';
import EuiOverlayMask from './eui-overlay-mask';
import { on } from '@ember/modifier';
//@ts-expect-error
import onKey from 'ember-keyboard/modifiers/on-key';
import { and, or, eq, not } from 'ember-truth-helpers';
import { hash } from '@ember/helper';
import outsideClickDetectorModifier from '../modifiers/outside-click-detector';
import resizeObserverModifier from '../modifiers/resize-observer';
import focusTrapModifier from 'ember-focus-trap';
import styleModifier from 'ember-style-modifier/modifiers/style';
import { element } from 'ember-element-helper';

export type EuiCollapsibleNavArgs = {
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

  as: string;

  size?: number;

  side?: 'left' | 'right';

  role?: null | string;

  ownFocus?: boolean;

  outsideClickCloses?: boolean;

  closeButtonPosition?: 'outside' | 'inside';

  paddingSize?: string;

  hideCloseButton?: boolean;

  closeButtonProps?: {
    className: string;
    onClick: (e: MouseEvent) => void;
  };

  closeButtonAriaLabel?: string;

  onClose: () => void;

  maxWidth?: boolean | number;

  maskProps?: Record<string, unknown>;

  type?: string;

  pushMinBreakpoint?: number | EuiBreakpointSize;
};

const classesModifier = modifier(
  (
    _element: HTMLElement,
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
      dimensions: { width?: string };
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

      if (isPushed) {
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

export default class EuiCollapsibleNavComponent extends Component<EuiCollapsibleNavArgs> {
  @tracked windowIsLargeEnoughToPush = isWithinMinBreakpoint(
    typeof window === 'undefined' ? -Infinity : window.innerWidth,
    this.pushMinBreakpoint
  );

  @tracked dimensions: undefined | { width: number; height: number };

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
    {{! @glint-nocheck: not typesafe yet }}
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
        focusTrapModifier
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
      as |classes closeButtonClasses focusTrap outsideClickDetector currentStyles onEscape classesModifier resizeObserver Element|
    }}

      {{#if (and this.ownFocus (not this.isPushed))}}
        <EuiOverlayMask @headerZindexLocation="below" @onClick={{this.onClose}}>
          <Element
            role={{this.role}}
            class={{classes}}
            tabindex={{-1}}
            {{currentStyles}}
            {{focusTrap}}
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
          </Element>
        </EuiOverlayMask>
      {{else if (not this.isPushed)}}
        <EuiPortal>
          <Element
            role={{this.role}}
            class={{classes}}
            tabindex={{-1}}
            {{currentStyles}}
            {{focusTrap}}
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
          </Element>
        </EuiPortal>
      {{else}}
        <Element
          role={{this.role}}
          class={{classes}}
          tabindex={{-1}}
          {{currentStyles}}
          {{focusTrap}}
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
        </Element>
      {{/if}}
    {{/let}}
  </template>
}
