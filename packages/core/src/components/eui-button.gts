import Component from '@glimmer/component';
import type { CSSObject } from '@emotion/css/create-instance';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiButtonDisplayStyles,
  euiButtonDisplayContentStyles,
  euiButtonDisplaysColors,
  euiFocusRing
} from '../utils/eui/styles.generated.ts';
import EuiButtonContent from './eui-button-content.gts';
import type { EuiButtonContentSignature } from './eui-button-content';

export interface EuiButtonSignature {
  /** A button, a link (with `@href`) or what `@element` names, e.g. a label. */
  Element: HTMLButtonElement | HTMLAnchorElement | HTMLLabelElement;
  Args: {
    /**
     * @private Class prefix, so other buttons can reuse this markup.
     * Defaults to `'euiButton'`.
     */
    baseClassName?: string;
    /**
     * `'primary'`, `'accent'`, `'success'`, `'warning'`, `'danger'`,
     * `'ghost'` (for dark backgrounds) or `'text'`. Defaults to `'primary'`.
     */
    color?: string;
    /** Classes for the element wrapping the icon and text. */
    contentClasses?: string;
    /** Same as `@isDisabled`. */
    disabled?: boolean;
    /**
     * Solid background, for the primary action of a page or form.
     * Defaults to `false` (light background).
     */
    fill?: boolean;
    /** Stretches the button to its container's width. */
    fullWidth?: boolean;
    /**
     * Renders an `<a>` link instead of a `<button>` (a disabled or loading
     * button stays a `<button>`).
     */
    href?: string;
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** `'right'` puts the icon after the text. Defaults to the left side. */
    iconSide?: EuiButtonContentSignature['Args']['iconSide'];
    /** Size of the icon. Defaults to `'m'`. */
    iconSize?: EuiButtonContentSignature['Args']['iconSize'];
    /** Icon next to the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiButtonContentSignature['Args']['iconType'];
    /** Shows a spinner instead of the icon and disables the button. */
    isLoading?: boolean;
    /** For toggle buttons: sets `aria-pressed="true"` while selected. */
    isSelected?: boolean;
    /** `'s'` or `'m'`. Defaults to `'m'`. */
    size?: string;
    /** `target` of the `@href` link, e.g. `'_blank'`. */
    target?: string;
    /** Classes for the element wrapping the text. */
    textClasses?: string;
    /**
     * `type` of the `<button>`, e.g. `'submit'` in a form.
     * Defaults to `'button'`.
     */
    type?: string;
    /** @deprecated Not needed: a component passed as `@iconType` is rendered. */
    useComponent?: boolean;
    /** @deprecated Has no effect, see `EuiIcon`. */
    useSvg?: boolean;
    /**
     * Tag to render, e.g. `'label'` for a file input trigger. Defaults to
     * `'a'` with `@href`, `'button'` otherwise.
     */
    element?: string;
    /** Disables the button and greys it out. */
    isDisabled?: boolean;
  };
  Blocks: {
    /** The button's text. */
    default: [];
  };
}

/** Native Ember button using the upstream EUI 123 / Borealis factories. */
export default class EuiButton extends Component<EuiButtonSignature> {
  get context() {
    return getEuiThemeContext(this);
  }
  get isDisabled() {
    return Boolean(
      this.args.isLoading || this.args.isDisabled || this.args.disabled
    );
  }
  get tagName() {
    return (
      this.args.element ?? (this.args.href && !this.isDisabled ? 'a' : 'button')
    );
  }
  get href() {
    return this.tagName === 'a' && !this.isDisabled
      ? this.args.href
      : undefined;
  }
  get type() {
    return this.tagName === 'button' ? (this.args.type ?? 'button') : undefined;
  }
  get pressed() {
    return this.args.isSelected === undefined
      ? undefined
      : String(this.args.isSelected);
  }
  get size(): 's' | 'm' {
    return this.args.size === 's' ? 's' : 'm';
  }
  get classes() {
    const base = this.args.baseClassName ?? 'euiButton';
    const context = this.context;
    const theme = context.upstream.euiTheme;
    const display = useEuiBorealisStyles(context, euiButtonDisplayStyles);
    const colors = useEuiBorealisStyles(context, euiButtonDisplaysColors);
    const color =
      this.args.color === 'ghost' ? 'text' : (this.args.color ?? 'primary');
    const colorStyles = colors[this.args.fill ? 'fill' : 'base']!;
    // A scoped equivalent of the React global reset. Deliberately no global injection.
    const reset: CSSObject = {
      boxSizing: 'border-box',
      border: 'none',
      margin: 0,
      padding: 0,
      fontFamily: theme.font.family,
      textDecoration: 'none'
    };
    const styles = euiClass(
      context,
      reset,
      `&:focus { ${euiFocusRing(context.upstream)} }`,
      display.euiButtonDisplay,
      display[this.size],
      this.args.fullWidth && display.fullWidth,
      this.isDisabled && display.isDisabled,
      colorStyles[this.isDisabled ? 'disabled' : color] ??
        colorStyles['primary']
    );
    return `${base} ${styles}`;
  }
  get contentClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiButtonDisplayContentStyles);
    const iconSize = {
      s: '12px',
      m: '16px',
      l: '24px',
      xl: '32px',
      xxl: '40px',
      original: 'auto'
    }[this.args.iconSize ?? 'm'];
    return [
      'euiButton__content',
      this.args.contentClasses,
      euiClass(context, styles.euiButtonDisplayContent, {
        boxSizing: 'border-box',
        flexDirection: this.args.iconSide === 'right' ? 'row-reverse' : 'row',
        '& .euiButtonContent__icon': {
          width: iconSize,
          height: iconSize,
          inlineSize: iconSize,
          blockSize: iconSize,
          fill: 'currentColor',
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
  get textClasses() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiButtonDisplayContentStyles
    );
    return [
      'euiButton__text',
      this.args.textClasses,
      euiClass(this.context, styles.content[this.size], {
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
        target={{@target}}
        aria-busy={{if @isLoading "true" null}}
        aria-pressed={{this.pressed}}
        type={{this.type}}
        {{!@glint-expect-error}}
        ...attributes
      >
        <EuiButtonContent
          class={{this.contentClasses}}
          @isLoading={{@isLoading}}
          @iconType={{@iconType}}
          @iconSize={{@iconSize}}
          @iconSide={{@iconSide}}
          @iconClasses={{@iconClasses}}
          @useSvg={{@useSvg}}
          @useComponent={{@useComponent}}
          @textClasses={{this.textClasses}}
        >{{yield}}</EuiButtonContent>
      </Element>
    {{/let}}
  </template>
}
