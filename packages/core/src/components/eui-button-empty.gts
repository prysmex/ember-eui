import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import type { CSSObject } from '@emotion/css/create-instance';
import { resolveButtonCommonProps } from '../-private/eui-button-context.ts';
import EuiButtonGroupItem from '../-private/eui-button-group-item.gts';
import euiApplyProps, { propsClasses } from '../-private/eui-apply-props.ts';
import type { EuiElementProps } from '../-private/eui-apply-props.ts';
import euiDisabledElement from '../-private/eui-disabled-element.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiButtonDisplayContentStyles,
  euiButtonDisplaysColors,
  euiButtonEmptyStyles,
  euiFocusRing
} from '../utils/eui/styles.generated.ts';
import EuiButtonContent from './eui-button-content.gts';

import type { EuiButtonContentSignature } from './eui-button-content';
import type { EuiIconSignature } from './eui-icon';
import type { EuiButtonContext } from '../-private/eui-button-context.ts';


export interface EuiButtonEmptySignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    /** Shows a spinner instead of the icon and disables the button. */
    isLoading?: boolean;
    /** `'xs'`, `'s'` or `'m'`. Defaults to `'m'`. */
    size?: 'xs' | 's' | 'm';
    /** Size of the icon. Defaults to `'m'` (always `'s'` for `@size="xs"`). */
    iconSize?: EuiButtonContentSignature['Args']['iconSize'];
    /**
     * `'primary'`, `'accent'`, `'accentSecondary'`, `'success'`,
     * `'warning'`, `'danger'`, `'text'`, `'neutral'` or `'risk'`. `'ghost'`
     * is still accepted and renders as `'text'` (latest EUI dropped it): wrap
     * it in a dark `EuiEmotionProvider`. Defaults to `'primary'`.
     */
    color?: string;
    /** Icon next to the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiIconSignature['Args']['type'];
    /** `'right'` puts the icon after the text. Defaults to the left side. */
    iconSide?: EuiButtonContentSignature['Args']['iconSide'];
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** Classes for the element wrapping the text. */
    textClasses?: string;
    /** Classes for the element wrapping the icon and text. */
    contentClasses?: string;
    /**
     * Extra styles composed last into the class of the element wrapping the
     * icon and text (upstream's `contentProps.css`).
     */
    contentCss?: EuiCss;
    /**
     * Removes the padding on `'left'`, `'right'` or `'both'` sides, to align
     * the text with content above or below it.
     */
    flush?: 'left' | 'right' | 'both';
    /**
     * Renders an `<a>` link instead of a `<button>` (a disabled or loading
     * button stays a `<button>`).
     */
    href?: string;
    /** `target` of the `@href` link, e.g. `'_blank'`. */
    target?: string;
    /** Disables the button and greys it out. */
    isDisabled?: boolean;
    /**
     * Beta: with `@isDisabled`, renders `aria-disabled="true"` instead of the
     * native `disabled` attribute. The button keeps focus (e.g. for a
     * tooltip) while clicks, pointer and key events (except Tab and Escape)
     * are blocked. Style it with `[aria-disabled="true"]`, not `:disabled`.
     */
    hasAriaDisabled?: boolean;
    /**
     * @private Props cascaded by a parent `EuiButtonGroup` (curried into
     * the buttons it yields).
     */
    buttonContext?: EuiButtonContext;
    /** @deprecated Has no effect, see `EuiIcon`. */
    useSvg?: boolean;
    /** @deprecated Not needed: a component passed as `@iconType` is rendered. */
    useComponent?: boolean;
    /** `type` of the `<button>`, e.g. `'submit'`. Defaults to `'button'`. */
    type?: string;
    /**
     * For toggle buttons: sets `aria-pressed` to `"true"` / `"false"`. Leave
     * it undefined for regular buttons.
     */
    isSelected?: boolean;
    /** Same as `@isDisabled`. */
    disabled?: boolean;
    /**
     * Upstream's `contentProps`, for the element wrapping the icon and
     * text: `class`/`className`, `css` and HTML attributes (`data-*`,
     * `aria-*`, `title`, ...). Event handlers are not supported.
     */
    contentProps?: EuiElementProps;
    /**
     * Upstream's `textProps`, for the element wrapping the text, with the
     * same keys as `@contentProps`. `false` is not supported.
     */
    textProps?: EuiElementProps;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The button's text. */
    default: [];
  };
}

/** Native Ember empty button using the upstream EUI 123 / Borealis factories. */
export default class EuiButtonEmpty extends Component<EuiButtonEmptySignature> {
  get context() {
    return getEuiThemeContext(this);
  }
  @cached
  get common() {
    const args = this.args;
    return resolveButtonCommonProps({
      context: args.buttonContext,
      size: args.size,
      color: args.color,
      isDisabled: args.isDisabled,
      disabled: args.disabled,
      isLoading: args.isLoading,
      hasAriaDisabled: args.hasAriaDisabled
    });
  }
  get isDisabled() {
    return this.common.isDisabled;
  }
  get hasAriaDisabled() {
    return this.common.hasAriaDisabled;
  }
  /** Native `disabled`, unless `@hasAriaDisabled` swaps it for `aria-disabled`. */
  get disabledAttr() {
    return this.hasAriaDisabled ? undefined : this.isDisabled;
  }
  get ariaDisabled() {
    return this.hasAriaDisabled && this.isDisabled ? 'true' : undefined;
  }
  get tagName() {
    return this.args.href && !this.isDisabled ? 'a' : 'button';
  }
  get href() {
    return this.tagName === 'a' ? this.args.href : undefined;
  }
  get target() {
    return this.tagName === 'a' ? this.args.target : undefined;
  }
  get type() {
    return this.tagName === 'button' ? (this.args.type ?? 'button') : undefined;
  }
  get pressed() {
    return this.tagName === 'button' && this.args.isSelected !== undefined
      ? String(this.args.isSelected)
      : undefined;
  }
  get size(): 'xs' | 's' | 'm' {
    const size = this.common.size;
    return size === 'xs' || size === 's' ? size : 'm';
  }
  get iconSize() {
    return this.size === 'xs' ? 's' : (this.args.iconSize ?? 'm');
  }
  @cached
  get classes() {
    const context = this.context;
    const theme = context.upstream.euiTheme;
    const styles = useEuiBorealisStyles(context, euiButtonEmptyStyles);
    const colors = useEuiBorealisStyles(context, euiButtonDisplaysColors)[
      'empty'
    ]!;
    const color = this.common.color;
    const colorName = color === 'ghost' ? 'text' : (color ?? 'primary');
    const flush = this.args.flush;
    // A scoped equivalent of the React global reset. Deliberately no global injection.
    const reset: CSSObject = {
      boxSizing: 'border-box',
      border: 'none',
      margin: 0,
      padding: 0,
      background: 'none',
      fontFamily: theme.font.family,
      textDecoration: 'none'
    };
    const css = euiClass(
      context,
      reset,
      `&:focus { ${euiFocusRing(context.upstream)} }`,
      styles.euiButtonEmpty,
      styles[this.size],
      colors[this.isDisabled ? 'disabled' : colorName] ?? colors['primary'],
      flush && styles.flush,
      flush && styles[flush],
      this.isDisabled && styles.isDisabled,
      this.args.css
    );
    return `euiButtonEmpty ${css}`;
  }
  @cached
  get contentClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiButtonDisplayContentStyles);
    return [
      'euiButtonEmpty__content',
      this.args.contentClasses,
      propsClasses(this.args.contentProps),
      euiClass(context, styles.euiButtonDisplayContent, {
        boxSizing: 'border-box',
        flexDirection: this.args.iconSide === 'right' ? 'row-reverse' : 'row',
        '& .euiButtonContent__icon': {
          flexShrink: 0,
          margin: 0
        },
        '& .euiButtonContent__spinner': {
          margin: 0,
          borderColor: 'currentColor',
          borderRightColor: 'transparent'
        }
      }, this.args.contentCss, this.args.contentProps?.css)
    ]
      .filter(Boolean)
      .join(' ');
  }
  @cached
  get textClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiButtonDisplayContentStyles);
    return [
      'euiButtonEmpty__text',
      this.args.textClasses,
      propsClasses(this.args.textProps),
      euiClass(context, styles.content[this.size], {
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap',
        minInlineSize: 0
      }, this.args.textProps?.css)
    ]
      .filter(Boolean)
      .join(' ');
  }

  <template>
    <EuiButtonGroupItem @wrap={{@buttonContext.wrapInItem}}>
      {{#let (element this.tagName) as |Element|}}
        <Element
          class={{this.classes}}
          disabled={{this.disabledAttr}}
          aria-disabled={{this.ariaDisabled}}
          href={{this.href}}
          target={{this.target}}
          aria-busy={{if @isLoading "true" null}}
          aria-pressed={{this.pressed}}
          type={{this.type}}
          {{euiDisabledElement this.isDisabled this.hasAriaDisabled}}
          ...attributes
        >
          <EuiButtonContent
            class={{this.contentClasses}}
            @isLoading={{@isLoading}}
            @iconType={{@iconType}}
            @iconSide={{@iconSide}}
            @iconSize={{this.iconSize}}
            @iconClasses={{@iconClasses}}
            @useSvg={{@useSvg}}
            @useComponent={{@useComponent}}
            @textClasses={{this.textClasses}}
            @textProps={{@textProps}}
            {{euiApplyProps @contentProps}}
          >{{yield}}</EuiButtonContent>
        </Element>
      {{/let}}
    </EuiButtonGroupItem>
  </template>
}
