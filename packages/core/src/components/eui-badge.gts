import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, eq, not } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiBadgeStyles,
  getCustomInteractiveColors,
  getIsValidColor,
  getTextColor
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiThemeContext } from '../utils/emotion/context.ts';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Named badge colors of EUI 123 (Borealis). */
export const BADGE_COLORS = [
  'default',
  'hollow',
  'primary',
  'accent',
  'neutral',
  'success',
  'warning',
  'risk',
  'danger'
] as const;

export type EuiBadgeNamedColor = (typeof BADGE_COLORS)[number];

function isNamedColor(color: string): color is EuiBadgeNamedColor {
  return (BADGE_COLORS as readonly string[]).includes(color);
}

/**
 * Upstream `getSecureRelForTarget`: links always get `noreferrer`, and
 * `noopener` when they open a new window.
 */
export function secureRel(target?: string, rel?: string): string {
  const parts = rel
    ? rel.split(' ').filter((part) => part.length && part !== 'noreferrer')
    : [];
  parts.push('noreferrer');
  if ((target ?? '').includes('_blank') && !parts.includes('noopener')) {
    parts.push('noopener');
  }
  return parts.sort().join(' ').trim();
}

/** Upstream `validateHref`: `javascript:` URLs disable the badge. */
function isHrefValid(href: string): boolean {
  try {
    // A base keeps relative hrefs valid (upstream assumes absolute URLs).
    return new URL(href, 'http://localhost').protocol !== 'javascript:';
  } catch {
    return true;
  }
}

/**
 * The bits of React EUI's global reset (`*` box sizing, `button` reset and
 * the body font) that badges rely on. Composed before the upstream styles,
 * so every upstream declaration wins.
 */
export function euiBadgeReset({ euiTheme }: EuiBorealisContext): CSSObject {
  return {
    boxSizing: 'border-box',
    margin: 0,
    font: 'inherit',
    fontFamily: euiTheme.font.family,
    '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
  };
}

const buttonReset: CSSObject = {
  background: 'none',
  border: 'none',
  padding: 0,
  margin: 0,
  color: 'inherit',
  borderRadius: 0,
  font: 'inherit',
  cursor: 'pointer'
};

/**
 * EuiIcon is not migrated yet, so badges size and color its SVG locally like
 * upstream's EuiIcon `size="s"` (12px, `currentColor`).
 */
export function euiBadgeIconSizing(
  { euiTheme }: EuiBorealisContext,
  size: 's' | 'm' = 's'
): CSSObject {
  const length = size === 'm' ? euiTheme.size.base : euiTheme.size.m;
  return {
    display: 'inline-block',
    flexShrink: 0,
    verticalAlign: 'middle',
    fill: 'currentColor',
    inlineSize: length,
    blockSize: length
  };
}

export interface EuiBadgeSignature {
  Element: HTMLButtonElement | HTMLAnchorElement | HTMLSpanElement;
  Args: {
    /**
     * `'default'`, `'hollow'`, `'primary'`, `'accent'`, `'neutral'`,
     * `'success'`, `'warning'`, `'risk'`, `'danger'` or any CSS color
     * (`'#DA8B45'`, `'rgb(…)'`); custom colors get a text color picked for
     * contrast. Defaults to `'default'`.
     */
    color?: EuiBadgeNamedColor | string;
    /**
     * Named colors only: the stronger, filled variant of the color.
     * Defaults to `false`.
     */
    fill?: boolean;
    /**
     * Icon shown in the badge, anything `EuiIcon`'s `@type` accepts.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * Side of the text the icon is on (logical, so it flips in RTL).
     * Defaults to `'left'`.
     */
    iconSide?: 'left' | 'right';
    /**
     * Makes the icon a separate button calling this function, e.g. an "x" to
     * remove the badge. Requires `@iconType` and `@iconOnClickAriaLabel`.
     */
    iconOnClick?: (event: MouseEvent) => void;
    /**
     * Accessible label (and hover title) of the `@iconOnClick` button.
     */
    iconOnClickAriaLabel?: string;
    /**
     * @deprecated Has no effect, see `EuiIcon`.
     */
    iconUseSvg?: boolean;
    /**
     * Disables the badge's buttons and links and greys it out.
     */
    isDisabled?: boolean;
    /**
     * Makes the badge (or its text, with `@iconOnClick`) a button calling
     * this function.
     */
    onClick?: (event: MouseEvent) => void;
    /**
     * Accessible label of the `@onClick` button, when the text alone does not
     * describe the action.
     */
    onClickAriaLabel?: string;
    /**
     * Makes the badge (or its text, with `@iconOnClick`) a link.
     */
    href?: string;
    /**
     * `target` of the `@href` link, e.g. `'_blank'`.
     */
    target?: string;
    /**
     * `rel` of the `@href` link. `noreferrer` (and `noopener` for
     * `_blank`) is always added.
     */
    rel?: string;
    /**
     * Extra props for the `@iconOnClick` button.
     */
    closeButtonProps?: {
      tabIndex?: number;
      dataSelectedIconIndex?: number;
      iconClasses?: string;
    };
  };
  Blocks: {
    /** The badge's text. */
    default: [];
  };
}

/** A small label: `<EuiBadge @color="success">Done</EuiBadge>`. */
export default class EuiBadge extends Component<EuiBadgeSignature> {
  get context(): EuiThemeContext {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiBadgeStyles);
  }

  get color(): string {
    return this.args.color ?? 'default';
  }

  get isNamedColor(): boolean {
    return isNamedColor(this.color);
  }

  get isDisabled(): boolean {
    return Boolean(
      this.args.isDisabled || (this.args.href && !isHrefValid(this.args.href))
    );
  }

  get isClickable(): boolean {
    return Boolean(this.args.onClick || this.args.href);
  }

  /** `a` for enabled links, `button` otherwise (links cannot be disabled). */
  get isLink(): boolean {
    return Boolean(this.args.href && !this.isDisabled);
  }

  get rel(): string | undefined {
    return this.isLink ? secureRel(this.args.target, this.args.rel) : undefined;
  }

  get iconSide(): 'left' | 'right' {
    return this.args.iconSide ?? 'left';
  }

  /**
   * Upstream sets these as inline custom properties; a class keeps the
   * caller's `style` attribute intact.
   */
  get customColorCss(): CSSObject | undefined {
    if (this.isDisabled || this.isNamedColor) return undefined;
    const color = this.color;
    const upstream = this.context.upstream;
    try {
      const textColor = getTextColor(upstream, color) as string;
      const interactive = getCustomInteractiveColors(upstream, color) as {
        backgroundHover: string;
        backgroundActive: string;
      };
      return {
        '--euiBadgeBackgroundColor': color,
        '--euiBadgeTextColor': textColor,
        '--euiBadgeBackgroundHoverColor': interactive.backgroundHover,
        '--euiBadgeBackgroundActiveColor': interactive.backgroundActive
      };
    } catch {
      warn(
        `EuiBadge expects a valid color: a hex, rgb(a) or hsv value, or one of ${BADGE_COLORS.join(', ')}. Instead got ${color}.`,
        Boolean(getIsValidColor(color)),
        { id: 'ember-eui.eui-badge.invalid-color' }
      );
      return undefined;
    }
  }

  rootClass = (hasText: boolean): string => {
    const { styles, color, isNamedColor } = this;
    const { iconOnClick, iconType, fill } = this.args;
    const isRootButton = this.isClickable && !iconOnClick;
    const variant = isNamedColor
      ? color === 'hollow'
        ? 'hollow'
        : fill
          ? 'fill'
          : 'base'
      : 'custom';
    const named = color as EuiBadgeNamedColor;
    return euiClass(
      this.context,
      euiBadgeReset(this.context.upstream),
      isRootButton && !this.isLink ? buttonReset : undefined,
      styles.euiBadge,
      !hasText && iconType ? styles.iconOnly : undefined,
      ...(this.isDisabled
        ? [styles.disabled]
        : [
            isNamedColor && fill ? styles.colors.fill[named] : undefined,
            isNamedColor && !fill ? styles.colors.base[named] : undefined,
            isRootButton ? styles.clickable[variant] : undefined,
            iconOnClick && !this.isClickable
              ? styles.iconClickable[variant]
              : undefined
          ]),
      this.customColorCss
    );
  };

  @cached
  get contentClass(): string {
    return euiClass(this.context, this.styles.euiBadge__content);
  }

  @cached
  get textClass(): string {
    const { text } = this.styles;
    return euiClass(
      this.context,
      text.euiBadge__text,
      this.isClickable && !this.isDisabled ? text.clickable : undefined
    );
  }

  @cached
  get iconClass(): string {
    const { icon } = this.styles;
    return euiClass(
      this.context,
      euiBadgeIconSizing(this.context.upstream),
      icon.euiBadge__icon,
      icon[this.iconSide]
    );
  }

  @cached
  get iconButtonClass(): string {
    const { iconButton } = this.styles;
    return euiClass(
      this.context,
      buttonReset,
      iconButton.euiBadge__iconButton,
      iconButton[this.iconSide]
    );
  }

  @cached
  get childButtonClass(): string {
    return euiClass(
      this.context,
      this.isLink ? undefined : buttonReset,
      this.styles.euiBadge__childButton
    );
  }

  <template>
    {{#let (if (has-block) true false) as |hasText|}}
      <EuiInnerText as |ref innerText|>
        {{#if (and @iconOnClick this.isClickable)}}
          {{! icon button and text button/link side by side }}
          <span class="euiBadge {{this.rootClass hasText}}" ...attributes>
            <span class="euiBadge__content {{this.contentClass}}">
              {{#if @iconType}}
              {{#if (eq this.iconSide "left")}}
                <BadgeIcon
                  @type={{@iconType}}
                  @useSvg={{@iconUseSvg}}
                  @iconClass={{this.iconClass}}
                  @buttonClass={{this.iconButtonClass}}
                  @onClick={{@iconOnClick}}
                  @ariaLabel={{@iconOnClickAriaLabel}}
                  @disabled={{this.isDisabled}}
                  @closeButtonProps={{@closeButtonProps}}
                />
              {{/if}}
              {{/if}}
              {{#if this.isLink}}
                <a
                  class="euiBadge__childButton {{this.childButtonClass}}"
                  aria-label={{@onClickAriaLabel}}
                  title={{innerText}}
                  href={{@href}}
                  target={{@target}}
                  rel={{this.rel}}
                  {{didInsert ref}}
                  {{on "click" (optional @onClick)}}
                >{{yield}}</a>
              {{else}}
                <button
                  type="button"
                  class="euiBadge__childButton {{this.childButtonClass}}"
                  aria-label={{@onClickAriaLabel}}
                  title={{innerText}}
                  disabled={{this.isDisabled}}
                  {{didInsert ref}}
                  {{on "click" (optional @onClick)}}
                >{{yield}}</button>
              {{/if}}
              {{#if @iconType}}
              {{#if (eq this.iconSide "right")}}
                <BadgeIcon
                  @type={{@iconType}}
                  @useSvg={{@iconUseSvg}}
                  @iconClass={{this.iconClass}}
                  @buttonClass={{this.iconButtonClass}}
                  @onClick={{@iconOnClick}}
                  @ariaLabel={{@iconOnClickAriaLabel}}
                  @disabled={{this.isDisabled}}
                  @closeButtonProps={{@closeButtonProps}}
                />
              {{/if}}
              {{/if}}
            </span>
          </span>
        {{else}}
          {{#let
            (component
              BadgeContent
              contentClass=this.contentClass
              textClass=this.textClass
              hasText=hasText
              iconSide=this.iconSide
              iconType=@iconType
              iconUseSvg=@iconUseSvg
              iconClass=this.iconClass
              iconButtonClass=this.iconButtonClass
              iconOnClick=@iconOnClick
              iconOnClickAriaLabel=@iconOnClickAriaLabel
              isDisabled=this.isDisabled
              closeButtonProps=@closeButtonProps
            )
            as |Content|
          }}
            {{#if (and (not @iconOnClick) this.isLink)}}
              <a
                class="euiBadge {{this.rootClass hasText}}"
                aria-label={{@onClickAriaLabel}}
                title={{innerText}}
                href={{@href}}
                target={{@target}}
                rel={{this.rel}}
                ...attributes
                {{didInsert ref}}
                {{on "click" (optional @onClick)}}
              ><Content>{{yield}}</Content></a>
            {{else if (and (not @iconOnClick) this.isClickable)}}
              <button
                type="button"
                class="euiBadge {{this.rootClass hasText}}"
                aria-label={{@onClickAriaLabel}}
                title={{innerText}}
                disabled={{this.isDisabled}}
                ...attributes
                {{didInsert ref}}
                {{on "click" (optional @onClick)}}
              ><Content>{{yield}}</Content></button>
            {{else}}
              <span
                class="euiBadge {{this.rootClass hasText}}"
                title={{innerText}}
                ...attributes
                {{didInsert ref}}
              ><Content>{{yield}}</Content></span>
            {{/if}}
          {{/let}}
        {{/if}}
      </EuiInnerText>
    {{/let}}
  </template>
}

interface BadgeIconSignature {
  Args: {
    type: EuiIconSignature['Args']['type'];
    useSvg?: boolean;
    iconClass: string;
    buttonClass: string;
    onClick?: (event: MouseEvent) => void;
    ariaLabel?: string;
    disabled: boolean;
    closeButtonProps?: EuiBadgeSignature['Args']['closeButtonProps'];
  };
}

const BadgeIcon: TemplateOnlyComponent<BadgeIconSignature> = <template>
  {{#if @onClick}}
    <button
      type="button"
      class="euiBadge__iconButton {{@buttonClass}}"
      aria-label={{@ariaLabel}}
      disabled={{@disabled}}
      title={{@ariaLabel}}
      tabindex={{@closeButtonProps.tabIndex}}
      data-selected-index={{@closeButtonProps.dataSelectedIconIndex}}
      {{on "click" @onClick}}
    >
      <EuiIcon
        @color="inherit"
        @iconClasses="euiBadge__icon {{@closeButtonProps.iconClasses}} {{@iconClass}}"
        @type={{@type}}
        @useSvg={{@useSvg}}
        @size="s"
      />
    </button>
  {{else}}
    <EuiIcon
      @color="inherit"
      @iconClasses="euiBadge__icon {{@iconClass}}"
      @type={{@type}}
      @useSvg={{@useSvg}}
      @size="s"
    />
  {{/if}}
</template>;

interface BadgeContentSignature {
  Args: {
    contentClass: string;
    textClass: string;
    hasText: boolean;
    iconSide: 'left' | 'right';
    iconType?: EuiIconSignature['Args']['type'];
    iconUseSvg?: boolean;
    iconClass: string;
    iconButtonClass: string;
    iconOnClick?: (event: MouseEvent) => void;
    iconOnClickAriaLabel?: string;
    isDisabled: boolean;
    closeButtonProps?: EuiBadgeSignature['Args']['closeButtonProps'];
  };
  Blocks: { default: [] };
}

const BadgeContent: TemplateOnlyComponent<BadgeContentSignature> = <template>
  <span class="euiBadge__content {{@contentClass}}">
    {{#if @iconType}}
    {{#if (eq @iconSide "left")}}
      <BadgeIcon
        @type={{@iconType}}
        @useSvg={{@iconUseSvg}}
        @iconClass={{@iconClass}}
        @buttonClass={{@iconButtonClass}}
        @onClick={{@iconOnClick}}
        @ariaLabel={{@iconOnClickAriaLabel}}
        @disabled={{@isDisabled}}
        @closeButtonProps={{@closeButtonProps}}
      />
    {{/if}}
    {{/if}}
    {{#if @hasText}}
      <span class="euiBadge__text {{@textClass}}">{{yield}}</span>
    {{/if}}
    {{#if @iconType}}
    {{#if (eq @iconSide "right")}}
      <BadgeIcon
        @type={{@iconType}}
        @useSvg={{@iconUseSvg}}
        @iconClass={{@iconClass}}
        @buttonClass={{@iconButtonClass}}
        @onClick={{@iconOnClick}}
        @ariaLabel={{@iconOnClickAriaLabel}}
        @disabled={{@isDisabled}}
        @closeButtonProps={{@closeButtonProps}}
      />
    {{/if}}
    {{/if}}
  </span>
</template>;
