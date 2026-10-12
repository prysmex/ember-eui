import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import type { CSSObject } from '@emotion/css/create-instance';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiButtonDisplayContentStyles,
  euiButtonDisplaysColors,
  euiButtonEmptyStyles,
  euiFocusRing
} from '../utils/eui/styles.generated.ts';
import EuiButtonContent from './eui-button-content.gts';

import type { EuiButtonContentSignature } from './eui-button-content';
import type { EuiIconSignature } from './eui-icon';


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
  get isDisabled() {
    return Boolean(
      this.args.isLoading || this.args.isDisabled || this.args.disabled
    );
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
    const size = this.args.size;
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
    const color =
      this.args.color === 'ghost' ? 'text' : (this.args.color ?? 'primary');
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
      colors[this.isDisabled ? 'disabled' : color] ?? colors['primary'],
      flush && styles.flush,
      flush && styles[flush],
      this.isDisabled && styles.isDisabled
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
      })
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
      euiClass(context, styles.content[this.size], {
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap',
        minInlineSize: 0
      })
    ]
      .filter(Boolean)
      .join(' ');
  }

  <template>
    {{#let (element this.tagName) as |Element|}}
      <Element
        class={{this.classes}}
        disabled={{this.isDisabled}}
        href={{this.href}}
        target={{this.target}}
        aria-busy={{if @isLoading "true" null}}
        aria-pressed={{this.pressed}}
        type={{this.type}}
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
        >{{yield}}</EuiButtonContent>
      </Element>
    {{/let}}
  </template>
}
