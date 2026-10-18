import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles, euiClass } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiPanelStyles,
  euiBackgroundColor,
  euiPaddingSize,
  euiBorderColor
} from '../utils/eui/styles.generated.ts';

/** A box grouping content, with background, padding, border and shadow options. */
export interface EuiPanelSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Tag of a panel with `@onClick`. `'div'` (default) renders a
     * `<div role="button" tabindex="0">` that also reacts to Enter and Space;
     * `'button'` renders a native `<button type="button">` like upstream
     * (upstream's own default, kept as `'div'` here so existing panels
     * keep their markup). Ignored without `@onClick`.
     */
    element?: 'div' | 'button';
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
    /**
     * Adds a box shadow (plain panels without a border only). Defaults to `false`.
     */
    hasShadow?: boolean;
    /**
     * Adds a border (plain and transparent panels only). Defaults to `true`.
     */
    hasBorder?: boolean;
    /**
     * Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`.
     */
    paddingSize?: 'none' | 's' | 'm' | 'l';
    /**
     * `'none'` or `'m'`. Defaults to `'m'`.
     */
    borderRadius?: 'none' | 'm';
    /**
     * Background: `'plain'`, `'transparent'`, `'subdued'`, `'accent'`,
     * `'primary'`, `'success'`, `'warning'` or `'danger'`.
     * Defaults to `'plain'`.
     */
    color?:
      | 'transparent'
      | 'plain'
      | 'subdued'
      | 'accent'
      | 'primary'
      | 'success'
      | 'warning'
      | 'danger';
    /**
     * Grows to fill a flex parent's height. Defaults to `true`.
     */
    grow?: boolean;
    /**
     * Makes the whole panel clickable (hover styles, `role="button"`,
     * focusable, Enter and Space activate it).
     */
    onClick?: (e: MouseEvent) => void;
    /**
     * Hover styles for a clickable panel. Defaults to `true`.
     */
    isClickable?: boolean;
  };

  Blocks: {
    /** The panel's content. */
    default: [];
  };
}

/**
 * Enter and Space activate a clickable panel, like a native button. Keys
 * pressed in controls inside the panel are left alone.
 */
function activateOnKey(
  onClick: (e: MouseEvent) => void,
  event: KeyboardEvent
): void {
  if (event.target !== event.currentTarget) return;

  if (event.key === 'Enter' || event.key === ' ') {
    // Space would otherwise scroll the page
    event.preventDefault();
    onClick(event as unknown as MouseEvent);
  }
}

/** Borealis surface styles composed directly from the latest upstream factory. */
export default class EuiPanel extends Component<EuiPanelSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const upstream = context.upstream;
    const styles = useEuiBorealisStyles(context, euiPanelStyles);
    const color = this.args.color ?? 'plain';
    const hasBorder = this.args.hasBorder ?? true;
    const hasShadow = this.args.hasShadow ?? false;
    const canHaveBorder = color === 'plain' || color === 'transparent';
    const shadow =
      !hasBorder &&
      color === 'plain' &&
      !upstream.highContrastMode &&
      hasShadow;
    const clickable = !!this.args.onClick && (this.args.isClickable ?? true);
    const padding = this.args.paddingSize ?? 'm';
    const generated = euiClass(
      context,
      {
        boxSizing: 'border-box',
        display: 'block',
        padding: 0,
        border: 'none',
        borderRadius: 0,
        boxShadow: 'none',
        font: 'inherit',
        color: upstream.euiTheme.colors.textParagraph,
        textAlign: 'start'
      },
      styles.euiPanel,
      (this.args.grow ?? true) && styles.grow,
      styles.radius[this.args.borderRadius ?? 'm'],
      {
        padding: euiPaddingSize(upstream, padding) ?? 0,
        backgroundColor: euiBackgroundColor(upstream, color)
      },
      shadow && styles.hasShadow,
      canHaveBorder && hasBorder && styles.hasBorder,
      upstream.highContrastMode &&
        !(color === 'transparent' && !hasBorder) && {
          border: upstream.euiTheme.border.thin,
          borderColor: euiBorderColor(upstream, color)
        },
      clickable && styles.isClickable,
      clickable && {
        cursor: 'pointer',
        outlineOffset: '2px',
        '&:focus-visible': {
          outline: `${upstream.euiTheme.focus.width} solid ${upstream.euiTheme.focus.color}`
        }
      },
      this.args.css
    );
    // `euiPanel` like upstream, so upstream's `.euiPanel` selectors match;
    // `euiPanelBorealis`, the class this port used first, stays for apps
    return ['euiPanel', 'euiPanelBorealis', `euiPanel--${color}`, generated].join(' ');
  }

  <template>
    {{#if @onClick}}
      {{#if (eq @element "button")}}
        <button
          type="button"
          data-eui-panel
          class={{this.classes}}
          {{on "click" @onClick}}
          {{!@glint-expect-error}}
          ...attributes
        >
          {{yield}}
        </button>
      {{else}}
        <div
          role="button"
          data-eui-panel
          class={{this.classes}}
          tabindex="0"
          {{on "click" @onClick}}
          {{on "keydown" (fn activateOnKey @onClick)}}
          ...attributes
        >
          {{yield}}
        </div>
      {{/if}}
    {{else}}
      <div data-eui-panel class={{this.classes}} ...attributes>{{yield}}</div>
    {{/if}}
  </template>
}
