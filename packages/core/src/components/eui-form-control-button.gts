import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { formControlLayoutContext } from '../-private/eui-form-control-layout-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiFormControlButtonStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import euiApplyProps, { propsClasses } from '../-private/eui-apply-props.ts';
import EuiButtonEmpty from './eui-button-empty.gts';

import type { EuiElementProps } from '../-private/eui-apply-props.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiButtonEmptySignature } from './eui-button-empty';

/**
 * Upstream renders the button content without a text wrapper
 * (`textProps={false}`): EuiButtonEmpty always wraps its block, so the
 * wrapper is taken out of the layout and its children become the content's
 * flex items.
 */
const NO_TEXT_WRAPPER = {
  '& > .euiButtonEmpty__text': { display: 'contents' }
};

export interface EuiFormControlButtonSignature {
  Element: EuiButtonEmptySignature['Element'];
  Args: {
    /**
     * Text shown like an input value. It is also the `<button>`'s `value`.
     */
    value?: string;
    /** Text shown (in the placeholder color) while there is no `@value`. */
    placeholder?: string;
    /**
     * Shorter control. Defaults to the surrounding `EuiFormControlLayout`'s
     * `@compressed`.
     */
    compressed?: boolean;
    /**
     * Invalid styling. Defaults to the surrounding `EuiFormControlLayout`'s
     * `@isInvalid`.
     */
    isInvalid?: boolean;
    /** Stretches to the container's width. Defaults to `true` (upstream). */
    fullWidth?: boolean;
    /**
     * Disables the button. Defaults to the surrounding
     * `EuiFormControlLayout`'s disabled state.
     */
    isDisabled?: boolean;
    /**
     * Shows a spinner on the right and disables the button (not shown when
     * the surrounding layout already shows its own spinner).
     */
    isLoading?: boolean;
    /** Icon next to the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiButtonEmptySignature['Args']['iconType'];
    /** `'right'` puts the icon after the text. Defaults to the left side. */
    iconSide?: 'left' | 'right';
    /** Size of the icon. Defaults to `'m'`. */
    iconSize?: EuiButtonEmptySignature['Args']['iconSize'];
    /** Renders an `<a>` link instead of a `<button>`. */
    href?: string;
    /** `target` of the `@href` link. */
    target?: string;
    /** `type` of the `<button>`. Defaults to `'button'`. */
    type?: string;
    /** Beta: renders `aria-disabled` instead of `disabled`, see `EuiButtonEmpty`. */
    hasAriaDisabled?: boolean;
    /**
     * Upstream's `contentProps`: `class`/`className`, `css` and HTML
     * attributes for the element wrapping the icon and text.
     */
    contentProps?: EuiElementProps;
    /**
     * Upstream's `textProps`: `class`/`className`, `css` and HTML attributes
     * for the element holding the value or placeholder.
     */
    textProps?: EuiElementProps;
    /**
     * Extra styles composed last into the content element's class (upstream
     * `contentProps.css`).
     */
    contentCss?: EuiCss;
    /**
     * Extra styles composed last into the value/placeholder text's class
     * (upstream `textProps.css`).
     */
    textCss?: EuiCss;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** Content after the value/placeholder text, e.g. a badge. */
    default: [];
  };
}

/**
 * A button that looks like a form control (upstream `EuiFormControlButton`),
 * e.g. to open a picker from a form row.
 */
export default class EuiFormControlButton extends Component<EuiFormControlButtonSignature> {
  get context() {
    return getEuiThemeContext(this);
  }
  get layout() {
    return formControlLayoutContext(this);
  }
  get isDisabled() {
    return this.args.isDisabled ?? this.layout.isDisabled;
  }
  get isInvalid() {
    return this.args.isInvalid ?? this.layout.isInvalid;
  }
  get compressed() {
    return this.args.compressed ?? this.layout.compressed;
  }
  get isLoading() {
    return this.layout.isLoading === true ? false : this.args.isLoading;
  }
  get iconSide() {
    return this.isLoading ? 'right' : this.args.iconSide;
  }
  get hasText() {
    return Boolean(this.args.value || this.args.placeholder);
  }
  get value() {
    return this.args.value || undefined;
  }

  @cached
  get css() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiFormControlButtonStyles
    );
    return [
      styles.euiFormControlButton,
      this.isInvalid && styles.isInvalid,
      this.isLoading && styles.isLoading,
      this.layout.readOnly && styles.readOnly,
      this.compressed && styles.compressed,
      (this.args.fullWidth ?? true) ? styles.fullWidth : styles.formWidth,
      this.args.css
    ];
  }

  @cached
  get contentCss() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiFormControlButtonStyles
    );
    return [
      NO_TEXT_WRAPPER,
      styles.euiFormControlButton__content,
      !this.hasText && this.iconSide === 'right' && styles.alignEnd,
      this.args.contentCss
    ];
  }

  @cached
  get textClass() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFormControlButtonStyles);
    return `eui-textTruncate ${euiClass(
      context,
      euiTextTruncate(),
      styles.textContent,
      !this.args.value && styles.placeholder,
      this.args.textCss,
      this.args.textProps?.css
    )}`;
  }

  get textClasses() {
    return [this.textClass, propsClasses(this.args.textProps)].filter(Boolean).join(' ');
  }

  <template>
    <EuiButtonEmpty
      class="euiFormControlButton"
      value={{this.value}}
      @color="text"
      @css={{this.css}}
      @contentCss={{this.contentCss}}
      @isDisabled={{this.isDisabled}}
      @isLoading={{this.isLoading}}
      @hasAriaDisabled={{@hasAriaDisabled}}
      @contentProps={{@contentProps}}
      @iconType={{@iconType}}
      @iconSide={{this.iconSide}}
      @iconSize={{@iconSize}}
      @href={{@href}}
      @target={{@target}}
      @type={{@type}}
      ...attributes
    >
      {{#if this.hasText}}
        <span class={{this.textClasses}} {{euiApplyProps @textProps}}>{{if @value @value @placeholder}}</span>
      {{/if}}
      {{yield}}
    </EuiButtonEmpty>
  </template>
}
