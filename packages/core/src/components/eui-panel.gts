import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles, euiClass } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiPanelStyles,
  euiBackgroundColor,
  euiPaddingSize,
  euiBorderColor
} from '../utils/eui/styles.generated.ts';
import type {
  borderRadiusMapping,
  colorMapping,
  paddingSizeMapping
} from '../utils/css-mappings/eui-panel.ts';

/** A box grouping content, with background, padding, border and shadow options. */
export interface EuiPanelSignature {
  Element: HTMLDivElement;
  Args: {
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
    paddingSize?: keyof typeof paddingSizeMapping;
    /**
     * `'none'` or `'m'`. Defaults to `'m'`.
     */
    borderRadius?: keyof typeof borderRadiusMapping;
    /**
     * Background: `'plain'`, `'transparent'`, `'subdued'`, `'accent'`,
     * `'primary'`, `'success'`, `'warning'` or `'danger'`.
     * Defaults to `'plain'`.
     */
    color?: keyof typeof colorMapping;
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
    return ['euiPanelBorealis', `euiPanel--${color}`, generated].join(' ');
  }

  <template>
    {{#if @onClick}}
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
    {{else}}
      <div data-eui-panel class={{this.classes}} ...attributes>{{yield}}</div>
    {{/if}}
  </template>
}
