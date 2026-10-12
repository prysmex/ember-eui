import Component from '@glimmer/component';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiStyles } from '../utils/emotion/context.ts';

import type { EuiThemeContext } from '../utils/emotion/context.ts';

export interface EuiEmotionButtonSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    context?: EuiThemeContext;
    color?: 'primary' | 'success' | 'warning' | 'danger' | 'text';
    size?: 's' | 'm';
    fill?: boolean;
    fullWidth?: boolean;
    disabled?: boolean;
    isDisabled?: boolean;
    isLoading?: boolean;
    isSelected?: boolean;
    href?: string;
    target?: string;
    type?: 'button' | 'submit' | 'reset';
  };
  Blocks: { default: [] };
}

/** Opt-in button port. All styling is Emotion-owned, with no legacy EUI CSS. */
export default class EuiEmotionButton extends Component<EuiEmotionButtonSignature> {
  get context() {
    return this.args.context ?? getEuiThemeContext(this);
  }
  get isDisabled() {
    return Boolean(
      this.args.disabled || this.args.isDisabled || this.args.isLoading
    );
  }
  get isLink() {
    return Boolean(this.args.href && !this.isDisabled);
  }

  get styles() {
    return useEuiStyles(this.context, (theme) => {
      const color = this.args.color ?? 'primary';
      const foreground = theme.colors[color];
      const contrast = {
        primary: theme.colors.onPrimary,
        success: theme.colors.onSuccess,
        warning: theme.colors.onWarning,
        danger: theme.colors.onDanger,
        text: theme.colors.background
      }[color];
      return {
        label: 'eui-spike-button',
        boxSizing: 'border-box',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: theme.spacing,
        minHeight: this.args.size === 's' ? 32 : 40,
        padding: `0 ${theme.spacing * 2}px`,
        width: this.args.fullWidth ? '100%' : 'auto',
        border: `1px solid ${this.isDisabled ? theme.colors.disabled : foreground}`,
        borderRadius: theme.borderRadius,
        fontFamily: theme.fontFamily,
        fontSize: this.args.size === 's' ? 12 : 14,
        fontWeight: 600,
        lineHeight: 1.5,
        textDecoration: 'none',
        cursor: this.isDisabled ? 'not-allowed' : 'pointer',
        color: this.isDisabled
          ? theme.colors.disabled
          : this.args.fill
            ? contrast
            : foreground,
        backgroundColor:
          this.args.fill && !this.isDisabled
            ? foreground
            : theme.colors.background,
        opacity: this.isDisabled ? 0.65 : 1,
        transition: 'filter 120ms ease',
        '&:hover': this.isDisabled ? {} : { filter: 'brightness(0.92)' },
        '&:focus-visible': {
          outline: `2px solid ${theme.colors.focus}`,
          outlineOffset: 3
        },
        '&[aria-pressed="true"]': {
          boxShadow: `inset 0 0 0 1px ${foreground}`
        },
        '@media (prefers-reduced-motion: reduce)': { transition: 'none' }
      };
    });
  }

  get spinnerStyles() {
    const spin = this.context.cache.keyframes({
      to: { transform: 'rotate(360deg)' }
    });
    return this.context.cache.css({
      display: 'inline-block',
      width: 14,
      height: 14,
      border: '2px solid currentColor',
      borderRightColor: 'transparent',
      borderRadius: '50%',
      animation: `${spin} 700ms linear infinite`,
      '@media (prefers-reduced-motion: reduce)': { animation: 'none' }
    });
  }

  <template>
    {{#if this.isLink}}
      <a class={{this.styles}} href={{@href}} target={{@target}} ...attributes>
        {{yield}}
      </a>
    {{else}}
      <button
        class={{this.styles}}
        type={{if @type @type "button"}}
        disabled={{this.isDisabled}}
        aria-busy={{if @isLoading "true" null}}
        aria-pressed={{if @isSelected "true" null}}
        ...attributes
      >
        {{#if @isLoading}}<span
            class={{this.spinnerStyles}}
            aria-hidden="true"
          ></span>{{/if}}
        {{yield}}
      </button>
    {{/if}}
  </template>
}
