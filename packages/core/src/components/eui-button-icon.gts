import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';
import type { CSSObject } from '@emotion/css/create-instance';
import { modifier } from 'ember-modifier';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiButtonDisplaysColors,
  euiButtonIconStyles,
  euiFocusRing
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';

import type EuiConfigService from '../services/eui-config';
import type { EuiIconSignature } from './eui-icon';
import type { EuiLoadingSpinnerSignature } from './eui-loading-spinner';

type ButtonIconSize = 'xs' | 's' | 'm';
type ButtonIconDisplay = 'empty' | 'base' | 'fill';


/** Spinner border follows the (disabled) text color, as upstream does. */
const SPINNER_COLOR = { border: 'currentcolor' };

/**
 * Upstream parity for attributes the component only sees through
 * `...attributes`: warn when an icon-only button has no accessible name and
 * take an `aria-hidden` button out of the tab order.
 */
const iconButtonA11y = modifier(function iconButtonA11y(element: Element) {
  const ariaHidden = element.getAttribute('aria-hidden') === 'true';
  if (ariaHidden && !element.hasAttribute('tabindex')) {
    element.setAttribute('tabindex', '-1');
  }
  if (
    !ariaHidden &&
    !element.hasAttribute('aria-label') &&
    !element.hasAttribute('aria-labelledby')
  ) {
    console.warn(
      'EuiButtonIcon requires aria-label or aria-labelledby to be specified because icon-only buttons are screen-reader-inaccessible without them.'
    );
  }
});

export interface EuiButtonIconSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
    /**
     * The icon; anything `EuiIcon`'s `@type` accepts. An icon-only button
     * has no visible text, so always pass an `aria-label="…"` (or
     * `aria-labelledby`) describing the action; a warning is logged
     * otherwise.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /** Size of the icon. Defaults to `'m'`. */
    iconSize?: EuiIconSignature['Args']['size'];
    /** Extra classes for the icon. */
    iconClasses?: string;
    /**
     * Renders an `<a>` link instead of a `<button>` (a disabled or loading
     * button stays a `<button>`).
     */
    href?: string;
    /** `target` of the `@href` link, e.g. `'_blank'`. */
    target?: string;
    /** Disables the button and greys it out. */
    isDisabled?: boolean;
    /** Replaces the icon with a loading spinner and disables the button. */
    isLoading?: boolean;
    /**
     * For toggle buttons: sets `aria-pressed` to `"true"` / `"false"`. Leave
     * it undefined for regular buttons.
     */
    isSelected?: boolean;
    /**
     * `'empty'` (just the icon), `'base'` (light background) or `'fill'`
     * (solid background). Defaults to `'empty'`.
     */
    display?: 'empty' | 'base' | 'fill';
    /**
     * `'primary'`, `'accent'`, `'accentSecondary'`, `'success'`,
     * `'warning'`, `'danger'`, `'text'`, `'neutral'` or `'risk'`. `'ghost'`
     * is still accepted and renders as `'text'` (latest EUI dropped it): wrap
     * it in a dark `EuiEmotionProvider`. Defaults to `'primary'`.
     */
    color?: string;
    /**
     * Size of the button: `'xs'` (24px), `'s'` (32px) or `'m'` (40px).
     * Defaults to the `euiButtonIcon.size` config, or `'xs'`.
     */
    size?: 'xs' | 's' | 'm';
    /** `type` of the `<button>`. Defaults to `'button'`. */
    type?: 'button' | 'submit' | 'reset';
    /** @deprecated Has no effect, see `EuiIcon`. */
    useSvg?: boolean;
    /** @deprecated Not needed: a component passed as `@iconType` is rendered. */
    useComponent?: boolean;
    /** Same as `@isDisabled`. */
    disabled?: boolean;
  };
}

/** Native Ember icon button using the upstream EUI 123 / Borealis factories. */
export default class EuiButtonIcon extends Component<EuiButtonIconSignature> {
  @service('eui-config') declare euiConfig: EuiConfigService;

  a11y = iconButtonA11y;
  spinnerColor: EuiLoadingSpinnerSignature['Args']['color'] = SPINNER_COLOR;

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
  get size(): ButtonIconSize {
    const size: string | undefined =
      this.args.size ?? this.euiConfig.getConfig('euiButtonIcon.size');
    return size === 's' || size === 'm' ? size : 'xs';
  }
  get display(): ButtonIconDisplay {
    const display = this.args.display;
    return display === 'base' || display === 'fill' ? display : 'empty';
  }
  get iconSize() {
    return this.args.iconSize ?? 'm';
  }
  get spinnerSize() {
    // `original` has no spinner equivalent: use the spinner default.
    const size = this.iconSize;
    return (size as string) === 'original' ? undefined : size;
  }
  @cached
  get classes() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiButtonIconStyles);
    const colors = useEuiBorealisStyles(context, euiButtonDisplaysColors)[
      this.display
    ]!;
    const color =
      this.args.color === 'ghost' ? 'text' : (this.args.color ?? 'primary');
    // A scoped equivalent of the React global reset. Deliberately no global injection.
    const reset: CSSObject = {
      boxSizing: 'border-box',
      border: 'none',
      margin: 0,
      padding: 0,
      background: 'none',
      textDecoration: 'none'
    };
    const css = euiClass(
      context,
      reset,
      `&:focus { ${euiFocusRing(context.upstream)} }`,
      styles.euiButtonIcon,
      styles[this.size],
      colors[this.isDisabled ? 'disabled' : color] ?? colors['primary'],
      this.isDisabled && styles.isDisabled,
      {
        '& .euiButtonIcon__icon': {
          flexShrink: 0,
          margin: 0
        }
      },
      this.args.css
    );
    return `euiButtonIcon ${css}`;
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
        {{this.a11y}}
      >
        {{#if @iconType}}
          {{#if @isLoading}}
            <EuiLoadingSpinner
              class="euiButtonIcon__spinner"
              @size={{this.spinnerSize}}
              @color={{this.spinnerColor}}
            />
          {{else}}
            <EuiIcon
              @iconClasses="euiButtonIcon__icon {{@iconClasses}}"
              @type={{@iconType}}
              @size={{this.iconSize}}
              @useSvg={{@useSvg}}
              @useComponent={{@useComponent}}
              @color="inherit"
              aria-hidden="true"
            />
          {{/if}}
        {{/if}}
      </Element>
    {{/let}}
  </template>
}
