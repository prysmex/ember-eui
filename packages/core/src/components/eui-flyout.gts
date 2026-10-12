import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { service } from '@ember/service';

import { focusTrap } from 'ember-focus-trap';
import { modifier as functionModifier } from 'ember-modifier';
import style from 'ember-style-modifier/modifiers/style';

import setBodyClass from '../-private/set-body-class.ts';
import outsideClickDetectorModifier from '../modifiers/outside-click-detector.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  dialogDescription,
  flyoutZIndex,
  observeWidth,
  pushFlyoutPadding,
  reactInlineStyle
} from '../utils/eui/modal-flyout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  composeFlyoutInlineStyles,
  euiFlyoutCloseButtonStyles,
  euiFlyoutStyles,
  FLYOUT_SIZES,
  isEuiFlyoutSizeNamed
} from '../utils/eui/styles.generated.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiOverlayMask from './eui-overlay-mask.gts';
import EuiPortal from './eui-portal.gts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n.ts';
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
   * Width: `'s'`, `'m'`, `'l'` or `'fill'` (90%), a number in px or any
   * CSS width. Defaults to `'m'`.
   */
  size?: number | string;

  /**
   * Side of the window it slides in from (logical: `'right'` is the
   * inline end, so it mirrors in RTL). Defaults to `'right'`.
   */
  side?: 'left' | 'right';

  /**
   * `role` of the flyout. Defaults to `'dialog'` (with `aria-modal`); a
   * pushed flyout has no role unless you pass one. `null` for none.
   */
  role?: null | string;

  /**
   * Renders a mask over the page behind the flyout, which closes it when
   * clicked. Without it, the page stays usable. Defaults to `true`.
   */
  ownFocus?: boolean;

  /**
   * Without the mask (`@ownFocus={{false}}`), `true` closes the flyout on
   * clicks outside it. With the mask, `false` stops mask clicks from
   * closing it. Defaults to closing on mask clicks only.
   */
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
  paddingSize?: 'none' | 's' | 'm' | 'l' | string;

  /** Hides the close button (e.g. when the flyout has its own). */
  hideCloseButton?: boolean;

  /** Props for the close button: `{ className, onClick }`. */
  closeButtonProps?: {
    className?: string;
    onClick?: (e: MouseEvent) => void;
    classes?: string;
  };

  /** Accessible label of the close button. Defaults to "Close this dialog". */
  closeButtonAriaLabel?: string;

  /**
   * Called by the close button, Escape, the mask and outside clicks. Stop
   * rendering the flyout here. Without it there is no close button.
   */
  onClose?: () => void;

  /**
   * Caps the width: `true` for the size's max width, `false` for none, or
   * a number in px or any CSS width. Defaults to `false`.
   */
  maxWidth?: boolean | number | string;

  /**
   * Options for the mask: `{ headerZindexLocation: 'above' }` puts the
   * flyout and its mask above a fixed `EuiHeader`. Defaults to `'below'`.
   */
  maskProps?: { headerZindexLocation?: 'above' | 'below' };

  /**
   * `'overlay'` covers the page; `'push'` pads the page so the flyout sits
   * beside it (on windows at least `@pushMinBreakpoint` wide).
   * Defaults to `'overlay'`.
   */
  type?: 'overlay' | 'push' | string;

  /**
   * Minimum window width for `@type="push"`: a theme breakpoint name
   * (`'xs'` to `'xl'`) or px. Smaller windows get an overlay. Defaults
   * to `'l'`.
   */
  pushMinBreakpoint?: number | EuiBreakpointSize;

  /**
   * Slides the flyout in (only when the user allows motion). Defaults to
   * `true` for overlays and `false` for push flyouts.
   */
  hasAnimation?: boolean;

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

export const SIZES = FLYOUT_SIZES as unknown as readonly [
  's',
  'm',
  'l',
  'fill'
];
export type EuiFlyoutSize = (typeof SIZES)[number];

/** Upstream `EuiWindowEvent` keydown: Escape closes a flyout that is not pushed. */
const windowKeydown = functionModifier(
  (_element: Element, [handler]: [(event: KeyboardEvent) => void]) => {
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }
);

const windowResize = functionModifier(
  (_element: Element, [handler, enabled]: [() => void, boolean]) => {
    if (!enabled) return;
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }
);

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
  @service declare euiI18n: EuiI18n;

  @tracked windowWidth =
    typeof window === 'undefined' ? Infinity : window.innerWidth;

  /** Border-box width while pushed, for the body padding. */
  @tracked width?: number;

  id = guidFor(this);

  /** The flyout element, the focus trap's fallback. */
  element?: Element;

  registerElement = functionModifier((element: Element) => {
    this.element = element;
  });
  descriptionId = `${this.id}-description`;

  get as() {
    return this.args.as ?? 'div';
  }

  get closeButtonPosition() {
    return this.args.closeButtonPosition === 'outside' ? 'outside' : 'inside';
  }

  get ownFocus() {
    return this.args.ownFocus ?? true;
  }

  get side(): 'left' | 'right' {
    return this.args.side === 'left' ? 'left' : 'right';
  }

  get size() {
    return this.args.size ?? 'm';
  }

  get paddingSize(): 'none' | 's' | 'm' | 'l' {
    const size = this.args.paddingSize;
    return size === 'none' || size === 's' || size === 'm' ? size : 'l';
  }

  get maxWidth() {
    return this.args.maxWidth ?? false;
  }

  get type() {
    return this.args.type === 'push' ? 'push' : 'overlay';
  }

  get hasAnimation() {
    return this.args.hasAnimation ?? this.type === 'overlay';
  }

  get headerZindexLocation(): 'above' | 'below' {
    return this.args.maskProps?.headerZindexLocation === 'above'
      ? 'above'
      : 'below';
  }

  get pushMinWidth(): number {
    const min = this.args.pushMinBreakpoint ?? 'l';
    if (typeof min === 'number') return min;
    const breakpoints = getEuiThemeContext(this).upstream.euiTheme
      .breakpoint as Record<string, number>;
    return breakpoints[min] ?? Infinity;
  }

  get isPushed() {
    return this.type === 'push' && this.windowWidth >= this.pushMinWidth;
  }

  get hasOverlayMask() {
    return this.ownFocus && !this.isPushed;
  }

  get role() {
    if (this.args.role !== undefined) return this.args.role ?? undefined;
    return this.isPushed ? undefined : 'dialog';
  }

  get ariaModal() {
    return !this.isPushed &&
      (this.role === 'dialog' || this.role === 'alertdialog')
      ? 'true'
      : undefined;
  }

  get showCloseButton() {
    return Boolean(this.args.onClose) && !this.args.hideCloseButton;
  }

  get zIndex() {
    return flyoutZIndex(
      getEuiThemeContext(this).upstream,
      this.headerZindexLocation,
      this.isPushed
    );
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutStyles);
    const { size, side, isPushed } = this;
    return `euiFlyout ${euiClass(
      context,
      {
        boxSizing: 'border-box',
        // Upstream portals carry the provider's text color class.
        color: context.upstream.euiTheme.colors.textParagraph
      },
      styles.euiFlyout,
      styles.paddingSizes[this.paddingSize],
      isEuiFlyoutSizeNamed(size) ? styles[size as EuiFlyoutSize] : undefined,
      this.maxWidth === false ? styles.noMaxWidth : undefined,
      isPushed ? styles.push.push : styles.overlay.overlay,
      isPushed ? styles.push[side] : styles.overlay[side],
      this.hasAnimation ? undefined : styles.noAnimation,
      styles[side]
    )}`;
  }

  @cached
  get contentClass() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutStyles);
    return `euiFlyout__content ${euiClass(context, styles.content)}`;
  }

  @cached
  get inlineStyle() {
    const size = this.size;
    return reactInlineStyle(
      composeFlyoutInlineStyles(
        // React writes numeric widths as px
        typeof size === 'number' ? `${size}px` : size,
        'side-by-side',
        null,
        null,
        this.maxWidth,
        this.zIndex.flyout
      )
    );
  }

  /** Upstream overrides the mask's z-index with an `!important` class. */
  @cached
  get maskClass() {
    return euiClass(getEuiThemeContext(this), {
      zIndex: `${this.zIndex.mask} !important`
    });
  }

  get closeButtonClass() {
    const extra =
      this.args.closeButtonProps?.className ??
      this.args.closeButtonProps?.classes;
    return ['euiFlyout__closeButton', extra].filter(Boolean).join(' ');
  }

  /**
   * Upstream's close button `css`: positioning (`euiFlyout__closeButton`,
   * `outsideSide`) plus the look (`inside`: transparent background;
   * `outside`: XL shadow, no animation). Migrated children must not get a
   * second Emotion class, so until EuiButtonIcon's `@css` lands here the
   * positioning goes on a wrapper (`euiFlyout__closeButtonWrapper`) and
   * `closeButtonLookCss` is not applied yet; switch both to `@css` at merge.
   */
  @cached
  get closeButtonPositionCss() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutCloseButtonStyles);
    return [
      styles.euiFlyout__closeButton,
      this.closeButtonPosition === 'outside'
        ? styles.outsideSide[this.side]
        : undefined
    ];
  }

  @cached
  get closeButtonLookCss() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutCloseButtonStyles);
    return styles[this.closeButtonPosition];
  }

  @cached
  get closeButtonWrapperClass() {
    return `euiFlyout__closeButtonWrapper ${euiClass(
      getEuiThemeContext(this),
      // sized like the button, so `left`+`right` resolve as on upstream's button
      { display: 'flex', inlineSize: 'max-content' },
      ...this.closeButtonPositionCss
    )}`;
  }

  @cached
  get descriptionClass() {
    return euiScreenReaderOnlyClass(getEuiThemeContext(this));
  }

  @cached
  get focusTrapOptions() {
    return (
      this.args.focusTrapOptions ?? {
        allowOutsideClick: true,
        clickOutsideDeactivates: !this.ownFocus,
        escapeDeactivates: false,
        // upstream's focus lock tolerates flyouts without tabbable content
        fallbackFocus: () => this.element as HTMLElement
      }
    );
  }

  get description() {
    return this.hasOverlayMask
      ? this.euiI18n.lookupToken(
          'euiFlyout.screenReaderModalDialog',
          'You are in a modal dialog. Press Escape or tap/click outside the dialog on the shadowed overlay to close.'
        )
      : this.euiI18n.lookupToken(
          'euiFlyout.screenReaderNoOverlayMaskDialog',
          'You are in a modal dialog. To close the dialog, press Escape.'
        );
  }

  get closeLabel() {
    return (
      this.args.closeButtonAriaLabel ??
      this.args.closeAriaLabel ??
      this.euiI18n.lookupToken(
        'euiFlyoutCloseButton.ariaLabel',
        'Close this dialog'
      )
    );
  }

  /** Clicks outside close only without a mask and with `@outsideClickCloses`. */
  get outsideClickDisabled() {
    return (
      this.isPushed ||
      this.hasOverlayMask ||
      this.args.outsideClickCloses !== true
    );
  }

  close = () => {
    this.args.onClose?.();
  };

  onMaskClick = () => {
    if (this.args.outsideClickCloses !== false) this.close();
  };

  onKeyDown = (event: KeyboardEvent) => {
    if (!this.isPushed && event.key === 'Escape') {
      event.preventDefault();
      this.close();
    }
  };

  onCloseButtonClick = (event: MouseEvent) => {
    this.close();
    this.args.closeButtonProps?.onClick?.(event);
  };

  onWindowResize = () => {
    this.windowWidth = window.innerWidth;
  };

  setWidth = (width: number) => {
    if (width !== this.width) this.width = width;
  };

  <template>
    {{(setBodyClass "euiBody--hasFlyout")}}
    {{#if this.hasOverlayMask}}
      <EuiOverlayMask
        class={{this.maskClass}}
        @headerZindexLocation={{this.headerZindexLocation}}
        @hasAnimation={{this.hasAnimation}}
        @onClick={{this.onMaskClick}}
      />
    {{/if}}
    {{#let
      (element this.as)
      (modifier
        focusTrap
        isActive=(if (eq @isFocusTrapActive false) false true)
        shouldSelfFocus=(if (eq @shouldSelfFocus false) false true)
        isPaused=this.isPushed
        focusTrapOptions=this.focusTrapOptions
      )
      (modifier
        outsideClickDetectorModifier
        isDisabled=this.outsideClickDisabled
        onOutsideClick=this.close
      )
      (modifier
        pushFlyoutPadding
        id=this.id
        side=this.side
        width=this.width
        isPushed=this.isPushed
      )
      (modifier observeWidth this.setWidth this.isPushed)
      as |TheElement trap outsideClick pushPadding measure|
    }}
      {{#if this.isPushed}}
        <TheElement
          class={{this.classes}}
          role={{this.role}}
          ...attributes
          {{style this.inlineStyle}}
          {{this.registerElement}}
          {{trap}}
          {{outsideClick}}
          {{dialogDescription this.descriptionId enabled=false}}
          {{measure}}
          {{pushPadding}}
          {{windowResize this.onWindowResize (eq this.type "push")}}
          {{windowKeydown this.onKeyDown}}
        >
          {{#if this.showCloseButton}}
            <span class={{this.closeButtonWrapperClass}}>
              <EuiButtonIcon
                @display={{if
                  (eq this.closeButtonPosition "outside")
                  "fill"
                  "empty"
                }}
                @iconType="cross"
                @color="text"
                aria-label={{this.closeLabel}}
                data-test-subj="euiFlyoutCloseButton"
                class={{this.closeButtonClass}}
                {{on "click" this.onCloseButtonClick}}
              />
            </span>
          {{/if}}
          <div class={{this.contentClass}} data-test-subj="euiFlyoutContent">
            {{yield}}
          </div>
        </TheElement>
      {{else}}
        <EuiPortal>
          <TheElement
            class={{this.classes}}
            role={{this.role}}
            aria-modal={{this.ariaModal}}
            tabindex="0"
            data-autofocus="true"
            ...attributes
            {{style this.inlineStyle}}
            {{this.registerElement}}
            {{trap}}
            {{outsideClick}}
            {{dialogDescription this.descriptionId}}
            {{windowResize this.onWindowResize (eq this.type "push")}}
            {{windowKeydown this.onKeyDown}}
          >
            {{! upstream EuiScreenReaderOnly clones its child: a bare <p> }}
            <p
              id={{this.descriptionId}}
              class={{this.descriptionClass}}
            >{{this.description}}</p>
            {{#if this.showCloseButton}}
              <span class={{this.closeButtonWrapperClass}}>
                <EuiButtonIcon
                  @display={{if
                    (eq this.closeButtonPosition "outside")
                    "fill"
                    "empty"
                  }}
                  @iconType="cross"
                  @color="text"
                  aria-label={{this.closeLabel}}
                  data-test-subj="euiFlyoutCloseButton"
                  class={{this.closeButtonClass}}
                  {{on "click" this.onCloseButtonClick}}
                />
              </span>
            {{/if}}
            <div class={{this.contentClass}} data-test-subj="euiFlyoutContent">
              {{yield}}
            </div>
          </TheElement>
        </EuiPortal>
      {{/if}}
    {{/let}}
  </template>
}

function eq(a: unknown, b: unknown) {
  return a === b;
}

