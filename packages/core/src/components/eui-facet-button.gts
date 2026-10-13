import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import euiApplyProps, { euiMinInlineSize, propsClasses } from '../-private/eui-apply-props.ts';
import euiDisabledElement from '../-private/eui-disabled-element.ts';
import type { EuiElementProps } from '../-private/eui-apply-props.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiButtonDisplayContentStyles,
  euiButtonDisplayStyles,
  euiFacetButton__disabled,
  euiFacetButtonStyles,
  euiFacetButtonTextStyles,
  euiFocusRing
} from '../utils/eui/styles.generated.ts';
import EuiInnerText from './eui-inner-text.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiNotificationBadge from './eui-notification-badge.gts';

/**
 * A button to filter by one value (a facet), usually with the number of
 * matching items. Put several in an `EuiFacetGroup`.
 */
export interface EuiFacetButtonSignature {
  Element: HTMLButtonElement | HTMLAnchorElement | HTMLSpanElement;
  Args: {
    /** Number of matching items, shown in a badge. */
    quantity?: number;
    /** Selected look: bold text and an accent badge. */
    isSelected?: boolean;
    /** Disables the button. */
    isDisabled?: boolean;
    /** Replaces the quantity with a spinner and disables the button. */
    isLoading?: boolean;
    /** Tag to render: `'button'` (default), `'a'` or `'span'`. */
    element?: 'a' | 'button' | 'span';
    /** Stretches the button to its container's width. */
    fullWidth?: boolean;
    /**
     * Beta: with `@isDisabled`, renders `aria-disabled` instead of the native
     * `disabled`; the button keeps focus while clicks are blocked.
     */
    hasAriaDisabled?: boolean;
    /** Overrides the minimum width: a CSS length or a number of pixels. */
    minWidth?: string | number | false;
    /** `'s'` (default) or `'m'`. */
    size?: 's' | 'm';
    /**
     * Upstream's `contentProps`: `class`/`className`, `css` and HTML
     * attributes for the element wrapping the icon, text and quantity.
     */
    contentProps?: EuiElementProps;
  };
  Blocks: {
    /** The facet's name. */
    default: [];
    /**
     * An icon or avatar before the name; give it the class
     * `euiFacetButton__icon`, e.g. `<EuiIcon class="euiFacetButton__icon" … />`.
     */
    icon: [];
  };
}

/**
 * Upstream applies `euiFacetButton__disabled` to the icon and the quantity.
 * The icon is the caller's block content, so it is reached from here; the
 * quantity badge gets it through `@css` (`quantityCss`).
 */
const DISABLED_CHILDREN = {
  '&:disabled .euiFacetButton__icon': euiFacetButton__disabled
};

export default class EuiFacetButton extends Component<EuiFacetButtonSignature> {
  get context() {
    return getEuiThemeContext(this);
  }
  get isDisabled() {
    return Boolean(this.args.isDisabled || this.args.isLoading);
  }
  get tagName() {
    return this.args.element ?? 'button';
  }
  get disabledAttr() {
    return this.args.hasAriaDisabled ? undefined : this.isDisabled;
  }
  get ariaDisabled() {
    return this.args.hasAriaDisabled && this.isDisabled ? 'true' : undefined;
  }
  get type() {
    return this.tagName === 'button' ? 'button' : undefined;
  }
  @cached
  get quantityCss(): EuiCss {
    return this.isDisabled ? euiFacetButton__disabled : undefined;
  }

  get hasQuantity() {
    return typeof this.args.quantity === 'number';
  }
  get badgeColor(): 'subdued' | 'accent' {
    return !this.args.isSelected || this.isDisabled ? 'subdued' : 'accent';
  }

  @cached
  get classes() {
    const context = this.context;
    const theme = context.upstream.euiTheme;
    const display = useEuiBorealisStyles(context, euiButtonDisplayStyles);
    const styles = useEuiBorealisStyles(context, euiFacetButtonStyles);
    return `euiFacetButton ${euiClass(
      context,
      // React's global `button` reset, scoped.
      {
        boxSizing: 'border-box',
        margin: 0,
        padding: 0,
        border: 'none',
        background: 'none',
        color: 'inherit',
        fontFamily: theme.font.family,
        textDecoration: 'none'
      },
      `&:focus { ${euiFocusRing(context.upstream)} }`,
      display.euiButtonDisplay,
      display[this.args.size === 'm' ? 'm' : 's'],
      this.args.fullWidth && display.fullWidth,
      this.isDisabled && display.isDisabled,
      styles.euiFacetButton,
      DISABLED_CHILDREN
    )}`;
  }

  @cached
  get contentClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiButtonDisplayContentStyles);
    return `euiFacetButton__content ${propsClasses(this.args.contentProps)} ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiButtonDisplayContent,
      this.args.contentProps?.css
    )}`;
  }

  @cached
  get textClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFacetButtonTextStyles);
    return `euiFacetButton__text ${euiClass(
      context,
      styles.euiFacetButton__text,
      styles[this.args.isSelected ? 'isSelected' : 'unSelected']
    )}`;
  }

  <template>
    <EuiInnerText as |ref innerText|>
      {{#let (element this.tagName) as |Element|}}
      <Element
        type={{this.type}}
        class={{this.classes}}
        disabled={{this.disabledAttr}}
        aria-disabled={{this.ariaDisabled}}
        title={{innerText}}
        {{euiDisabledElement this.isDisabled @hasAriaDisabled}}
        {{euiMinInlineSize @minWidth}}
        ...attributes
      >
        <span class={{this.contentClasses}} {{euiApplyProps @contentProps}}>
          {{yield to="icon"}}
          <span
            class={{this.textClasses}}
            data-text={{innerText}}
            {{didInsert ref}}
          >{{yield}}</span>
          {{#if @isLoading}}
            <EuiLoadingSpinner class="euiFacetButton__spinner" @size="m" />
          {{else if this.hasQuantity}}
            <EuiNotificationBadge
              class="euiFacetButton__quantity"
              @css={{this.quantityCss}}
              @size="m"
              @color={{this.badgeColor}}
            >{{@quantity}}</EuiNotificationBadge>
          {{/if}}
        </span>
      </Element>
      {{/let}}
    </EuiInnerText>
  </template>
}
