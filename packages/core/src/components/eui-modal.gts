import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { service } from '@ember/service';

import { focusTrap } from 'ember-focus-trap';
import style from 'ember-style-modifier/modifiers/style';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { dialogDescription } from '../utils/eui/modal-flyout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiModalStyles } from '../utils/eui/styles.generated.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiOverlayMask from './eui-overlay-mask.gts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n.ts';

type FocusTarget = string | HTMLElement | (() => HTMLElement);

/**
 * A dialog over the page, with a mask behind it. Render it only while
 * open: `{{#if this.isOpen}}<EuiModal @onClose={{…}}>…</EuiModal>{{/if}}`.
 * For yes/no questions use EuiConfirmModal.
 *
 * The modal is a `role="dialog"` with `aria-modal="true"`, described by a
 * screen reader hint and, unless you pass `aria-label`/`aria-labelledby`,
 * labelled by its `EuiModalHeaderTitle`. Pass `role="alertdialog"` for
 * destructive confirmations.
 */
/** Upstream `focusTrapProps` of a modal (`EuiFocusTrap`'s `returnFocus`). */
export interface EuiModalFocusTrapProps {
  /**
   * Whether closing returns focus to the element focused before opening:
   * `false` opts out (return it yourself), a function receives that
   * element and returns `false` to skip it. Defaults to `true`.
   */
  returnFocus?:
    | boolean
    | FocusOptions
    | ((returnTo: Element) => boolean | FocusOptions);
}

export interface EuiModalSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Called by the close button, Escape and (with `@clickOutsideToClose`)
     * clicks on the mask. Stop rendering the modal here.
     */
    onClose?: (e: Event) => void;
    /** Accessible label of the close button. Defaults to "Close this dialog". */
    closeButtonAriaLabel?: string;
    /**
     * `true` for EUI's default max width (the `m` breakpoint, 768px),
     * `false` for none (the window width), a number in px or any CSS width
     * (e.g. `'800px'`). Defaults to `true`.
     */
    maxWidth?: boolean | number | string;
    /** Clicking the mask around the modal calls `@onClose`. */
    clickOutsideToClose?: boolean;
    /** Same as `@clickOutsideToClose` (upstream name). */
    outsideClickCloses?: boolean;
    /**
     * The element focused when the modal opens: a selector, an element or
     * a function returning one. Defaults to the modal itself.
     */
    initialFocus?: FocusTarget;
    /** Traps keyboard focus inside the modal. Defaults to `true`. */
    isFocusTrapActive?: boolean;
    /** Focuses the modal itself when it opens. Defaults to `true`. */
    shouldSelfFocus?: boolean;
    /** Pauses the focus trap, e.g. while a nested popover has focus. */
    isFocusTrapPaused?: boolean;
    /**
     * Options for the focus trap (focus-trap library), e.g.
     * `{ initialFocus: '#name' }` to focus a field when it opens. Outside
     * clicks reach the mask and Escape is left to the modal by default.
     */
    focusTrapOptions?: {
      allowOutsideClick?: boolean;
      clickOutsideDeactivates?: boolean;
      initialFocus?: FocusTarget;
      fallbackFocus?: FocusTarget;
      escapeDeactivates?: boolean;
      returnFocusOnDeactivate?: boolean;
      preventScroll?: boolean;
    };
    /** Focus trap options (upstream `focusTrapProps`): `returnFocus`. */
    focusTrapProps?: EuiModalFocusTrapProps;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** `EuiModalHeader`, `EuiModalBody` and `EuiModalFooter`. */
    default: [];
  };
}

export default class EuiModal extends Component<EuiModalSignature> {
  @service declare euiI18n: EuiI18n;

  descriptionId = `${guidFor(this)}-description`;

  get maxWidth() {
    return this.args.maxWidth ?? true;
  }

  get outsideClickCloses() {
    return Boolean(
      this.args.clickOutsideToClose ?? this.args.outsideClickCloses
    );
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiModalStyles);
    return `euiModal ${euiClass(
      context,
      {
        boxSizing: 'border-box',
        // Upstream portals carry the provider's text color class.
        color: context.upstream.euiTheme.colors.textParagraph
      },
      styles.euiModal,
      this.maxWidth === true ? styles.defaultMaxWidth : undefined,
      this.args.css
    )}`;
  }

  /**
   * Upstream's close button `css` (`euiModal__closeIcon`, all positioning),
   * composed into EuiButtonIcon's own class through `@css`.
   */
  @cached
  get closeIconCss() {
    const context = getEuiThemeContext(this);
    return useEuiBorealisStyles(context, euiModalStyles).euiModal__closeIcon;
  }

  @cached
  get descriptionClass() {
    return euiScreenReaderOnlyClass(getEuiThemeContext(this));
  }

  @cached
  get inlineStyle() {
    const { maxWidth } = this;
    if (typeof maxWidth === 'boolean') return {};
    return {
      maxInlineSize: typeof maxWidth === 'number' ? `${maxWidth}px` : maxWidth
    };
  }

  @cached
  get focusTrapOptions() {
    const options = {
      allowOutsideClick: true,
      escapeDeactivates: false,
      ...(this.args.initialFocus
        ? { initialFocus: this.args.initialFocus }
        : {}),
      ...this.args.focusTrapOptions
    };
    const returnFocus = this.args.focusTrapProps?.returnFocus;

    if (returnFocus === false) {
      return { ...options, returnFocusOnDeactivate: false };
    }
    if (typeof returnFocus === 'function') {
      return {
        ...options,
        setReturnFocus: (previous: HTMLElement | SVGElement) =>
          returnFocus(previous) === false ? false : previous
      };
    }
    return options;
  }

  get description() {
    return this.euiI18n.lookupToken(
      'euiModal.screenReaderModalDialog',
      'You are in a modal dialog. Press Escape or tap/click outside the dialog on the shadowed overlay to close.'
    );
  }

  get closeLabel() {
    return this.args.closeButtonAriaLabel ?? 'Close this dialog';
  }

  onKeyDown = (event: KeyboardEvent) => {
    if (event.key !== 'Escape') return;
    const { target, currentTarget } = event;
    if (target instanceof Node && (currentTarget as Node).contains(target)) {
      event.preventDefault();
      event.stopPropagation();
      this.args.onClose?.(event);
    }
  };

  onMaskClick = (event: MouseEvent) => {
    if (this.outsideClickCloses) this.args.onClose?.(event);
  };

  onCloseClick = (event: MouseEvent) => {
    this.args.onClose?.(event);
  };

  <template>
    <EuiOverlayMask @onClick={{this.onMaskClick}}>
      <div
        class={{this.classes}}
        tabindex="0"
        role="dialog"
        aria-modal="true"
        ...attributes
        {{style this.inlineStyle}}
        {{dialogDescription
          this.descriptionId
          titleSelector=".euiModalHeader__title"
        }}
        {{focusTrap
          isActive=(if (eq @isFocusTrapActive false) false true)
          shouldSelfFocus=(if (eq @shouldSelfFocus false) false true)
          isPaused=(if @isFocusTrapPaused true false)
          focusTrapOptions=this.focusTrapOptions
        }}
        {{on "keydown" this.onKeyDown}}
      >
        {{yield}}
        {{! upstream EuiScreenReaderOnly clones its child: a bare <p> }}
        <p
          id={{this.descriptionId}}
          class={{this.descriptionClass}}
        >{{this.description}}</p>
        <EuiButtonIcon
          class="euiModal__closeIcon"
          @iconType="cross"
          @color="text"
          @css={{this.closeIconCss}}
          aria-label={{this.closeLabel}}
          {{on "click" this.onCloseClick}}
        />
      </div>
    </EuiOverlayMask>
  </template>
}

function eq(a: unknown, b: unknown) {
  return a === b;
}
