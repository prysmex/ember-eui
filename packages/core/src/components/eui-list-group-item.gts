import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { get } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

import { modifier } from 'ember-modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import euiDisabledElement from '../-private/eui-disabled-element.ts';
import EuiMaybeToolTip from '../-private/eui-maybe-tool-tip.gts';
import spreadAttributes from '../-private/eui-spread-attributes.ts';
import { listGroupContext } from '../-private/eui-list-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiListGroupItemExtraActionStyles,
  euiListGroupItemTooltipStyles,
  euiListGroupItemStyles,
  euiListItemLayoutStyles,
  euiListItemLayoutWrapperStyles,
  euiScreenReaderOnly
} from '../utils/eui/styles.generated.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';
import { getSecureRelForTarget, isValidHref } from './eui-link.gts';

import type { EuiButtonIconSignature } from './eui-button-icon';
import type { EuiIconSignature } from './eui-icon';
import type { EuiTooltipArgs } from './eui-tool-tip.gts';
import type { CSSInterpolation } from '@emotion/css/create-instance';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';

/** Upstream list item colors (plus the Ember `inherit`/`ghost` extensions). */
export type EuiListGroupItemColor =
  | 'primary'
  | 'text'
  | 'subdued'
  | 'inherit'
  | 'ghost';

/**
 * Upstream `extraAction` props: an `EuiButtonIcon` rendered after the item,
 * shown on hover/focus of the item unless `alwaysShow`.
 */
export interface EuiListGroupItemExtraActionProps {
  iconType: EuiIconSignature['Args']['type'];
  /** Keeps the action visible instead of only on hover/focus. */
  alwaysShow?: boolean;
  onClick?: (event: MouseEvent) => void;
  isDisabled?: boolean;
  'aria-label'?: string;
  title?: string;
  color?: string;
  iconSize?: EuiButtonIconSignature['Args']['iconSize'];
  size?: EuiButtonIconSignature['Args']['size'];
  display?: EuiButtonIconSignature['Args']['display'];
  className?: string;
  /**
   * Styles composed after the upstream extra-action styles (upstream's
   * `css` prop on the action).
   */
  css?: EuiCss;
  'data-test-subj'?: string;
}

/**
 * Upstream `iconProps` (EuiIcon props without `type`) for the `@iconType`
 * icon, or the `css`/`className` of the `@icon` component.
 */
export interface EuiListGroupItemIconProps {
  /** Defaults to `'inherit'` (the item's color). */
  color?: EuiIconSignature['Args']['color'];
  size?: EuiIconSignature['Args']['size'];
  title?: string;
  titleId?: string;
  /** Styles composed into the icon's class (upstream `css`). */
  css?: EuiCss;
  className?: string;
  /** Other keys (`aria-*`, `data-*`, …) become attributes of the icon. */
  [attribute: string]: unknown;
}

/** Keys of `@iconProps` that are EuiIcon args, not attributes. */
const ICON_ARGS = ['color', 'size', 'title', 'titleId', 'type'] as const;

export interface EuiListGroupItemSignature {
  Element:
    | HTMLLIElement
    | HTMLAnchorElement
    | HTMLButtonElement
    | HTMLSpanElement;
  Args: {
    /** Makes the item a link. A `javascript:` URL disables the item. */
    href?: string;
    /** `target` of the `@href` link. `'_blank'` adds the external icon. */
    target?: string;
    /** `rel` of the link; `noreferrer` (and `noopener` for `_blank`) is added. */
    rel?: string;
    /** Shows the external link icon; defaults to `true` for `_blank`. */
    external?: boolean;
    /** Makes the item a button calling this function. */
    onClick?: (event: MouseEvent) => void;
    /** The item's text. */
    label?: string;
    /** Icon before the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * Args for the `@iconType` icon (upstream `iconProps`): `color`
     * (defaults to `'inherit'`), `size`, `title`, `css`, `className` and
     * any attribute. With `@icon`, only `css` applies, as upstream.
     */
    iconProps?: EuiListGroupItemIconProps;
    /**
     * Custom icon (upstream's `icon` node): a component, e.g.
     * `(component EuiAvatar name="Jane" size="s")`, rendered with the
     * `euiListGroupItem__icon` class. `@iconType` wins when both are set.
     */
    icon?: ComponentLike<{ Element: Element }>;
    /** Highlights the item and sets `aria-current`, e.g. the current page. */
    isActive?: boolean;
    /** Disables the item. A disabled link renders a disabled `<button>`. */
    isDisabled?: boolean;
    /**
     * With `@isDisabled`, a link or button item stays focusable and gets
     * `aria-disabled` instead of `disabled` (e.g. so its tooltip still
     * shows); clicks and key presses are blocked.
     */
    hasAriaDisabled?: boolean;
    /**
     * Wraps long text instead of truncating it. Defaults to `false`. (The
     * list's `@wrapText` reaches only its `@listItems`, as upstream.)
     */
    wrapText?: boolean;
    /**
     * Rendered after the item: upstream's props object for an
     * `EuiButtonIcon` (`{ iconType, alwaysShow, onClick, 'aria-label', … }`),
     * or any component (use `(component …)`).
     */
    extraAction?: ComponentLike | EuiListGroupItemExtraActionProps;
    /**
     * Shows a tooltip with the label (or `@toolTipText`) on hover and focus.
     * Defaults to the list's `@showToolTips`, else `false`.
     */
    showToolTip?: boolean;
    /**
     * Text of the tooltip shown by `@showToolTip`. Defaults to the label:
     * the block's content when there is a block, else `@label`.
     */
    toolTipText?: string;
    /**
     * Customizes the tooltip shown by `@showToolTip`: the args of
     * `EuiToolTip` as an object (`position` defaults to `'right'`).
     */
    toolTipProps?: Partial<EuiTooltipArgs>;
    /** @deprecated Has no effect: latest EUI list items have one size. */
    size?: 'xs' | 's' | 'm' | 'l';
    /**
     * `'text'`, `'primary'` or `'subdued'`; `'inherit'` takes the parent's
     * color and `'ghost'` renders as `'text'` (latest EUI dropped it).
     * Defaults to the list's `@color`, else `'text'`.
     */
    color?: EuiListGroupItemColor | (string & {});
  };
  Blocks: {
    /**
     * Custom content instead of `@label` (upstream's `label` node). It is
     * also the tooltip's content without `@toolTipText`, and its text is the
     * `title` of a truncated label.
     */
    default: [];
  };
}

/**
 * Upstream `EuiListItemLayout` sets the tooltip id on a plain `<li>` (the
 * tooltip is inside it): `classNames(tooltipId, aria-describedby)`. Only the
 * id added here is removed again.
 */
const describedByToolTip = modifier(
  (element: HTMLElement, [id]: [string | undefined]) => {
    if (!id) return;
    const current = (element.getAttribute('aria-describedby') ?? '')
      .split(/\s+/)
      .filter(Boolean);
    if (current.includes(id)) return;
    element.setAttribute('aria-describedby', [id, ...current].join(' '));
    return () => {
      const remaining = (element.getAttribute('aria-describedby') ?? '')
        .split(/\s+/)
        .filter((token) => token && token !== id);
      if (remaining.length) {
        element.setAttribute('aria-describedby', remaining.join(' '));
      } else {
        element.removeAttribute('aria-describedby');
      }
    };
  }
);

function isPlainObject(
  value: unknown
): value is EuiListGroupItemExtraActionProps {
  if (!value || typeof value !== 'object') return false;
  const proto = Object.getPrototypeOf(value) as unknown;
  return proto === Object.prototype || proto === null;
}

interface ContentSignature {
  Args: {
    contentClass: string;
    prependClass: string;
    textClass: string;
    iconType?: EuiIconSignature['Args']['type'];
    iconProps?: EuiListGroupItemIconProps;
    iconCss?: EuiCss;
    icon?: ComponentLike<{ Element: Element }>;
    iconClass?: string;
    title?: string;
    showExternal: boolean;
    newTab: boolean;
    externalIconCss: EuiCss;
    srOnlyClass: string;
    /** Tracks the label's text (`EuiInnerText`) for its `title`. */
    textRef?: (element: HTMLElement) => void;
  };
  Blocks: { default: []; after: [] };
}

/** Hands the label's element to `EuiInnerText` when there is a ref. */
const textRef = modifier(
  (element: HTMLElement, [ref]: [((element: HTMLElement) => void) | undefined]) => {
    ref?.(element);
  }
);

const Content: TemplateOnlyComponent<ContentSignature> = <template>
  <span class={{@contentClass}}>
    {{#if @iconType}}
      <span class={{@prependClass}}>
        <EuiIcon
          class="euiListGroupItem__icon {{@iconProps.className}}"
          @type={{@iconType}}
          @color={{if @iconProps.color @iconProps.color "inherit"}}
          @size={{@iconProps.size}}
          @title={{@iconProps.title}}
          @titleId={{@iconProps.titleId}}
          @css={{@iconCss}}
          {{spreadAttributes @iconProps ICON_ARGS}}
        />
      </span>
    {{else if @icon}}
      <span class={{@prependClass}}>
        <@icon class={{@iconClass}} />
      </span>
    {{/if}}
    <span class={{@textClass}} title={{@title}} {{textRef @textRef}}>
      {{yield}}
      {{#if @showExternal}}
        <EuiIcon
          @type="external"
          @size="m"
          class="euiListGroupItem__externalIcon"
          @css={{@externalIconCss}}
          role="presentation"
        />
        <span class={{@srOnlyClass}}>
          {{#if @newTab}}
            (external, opens in a new tab or window)
          {{else}}
            (external)
          {{/if}}
        </span>
      {{/if}}
    </span>
    {{yield to="after"}}
  </span>
</template>;

interface ExtraActionSignature {
  Args: {
    component?: ComponentLike;
    props?: EuiListGroupItemExtraActionProps;
    css: EuiCss;
    color: string;
    disabled: boolean;
  };
}

const ExtraAction: TemplateOnlyComponent<ExtraActionSignature> = <template>
  {{#if @component}}
    {{#let @component as |Action|}}
      <Action />
    {{/let}}
  {{else if @props}}
    <EuiButtonIcon
      class="euiListGroupItemExtraAction {{@props.className}}"
      @css={{@css}}
      @iconType={{@props.iconType}}
      @iconSize={{@props.iconSize}}
      @size={{@props.size}}
      @display={{@props.display}}
      @color={{@color}}
      @isDisabled={{@disabled}}
      aria-label={{get @props "aria-label"}}
      title={{@props.title}}
      data-test-subj={{get @props "data-test-subj"}}
      {{on "click" (optional @props.onClick)}}
    />
  {{/if}}
</template>;

/** Native Ember list item using the upstream EUI 123 / Borealis factories. */
export default class EuiListGroupItem extends Component<EuiListGroupItemSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  get color(): string {
    return this.args.color ?? listGroupContext(this)?.color ?? 'text';
  }

  /** Upstream: only the item's own `wrapText` (the list passes it to `listItems`). */
  get wrapText(): boolean {
    return Boolean(this.args.wrapText);
  }

  get isDisabled(): boolean {
    const { href, isDisabled } = this.args;
    return Boolean(isDisabled || (href && !isValidHref(href)));
  }

  get isActive(): boolean {
    return Boolean(this.args.isActive);
  }

  get hasAriaDisabled(): boolean {
    return Boolean(this.args.hasAriaDisabled);
  }

  /** Native `disabled`, unless `@hasAriaDisabled` swaps it for `aria-disabled`. */
  get nativeDisabled(): boolean | undefined {
    return this.hasAriaDisabled ? undefined : this.isDisabled;
  }

  get buttonAriaDisabled(): 'true' | undefined {
    return this.hasAriaDisabled && this.isDisabled ? 'true' : undefined;
  }

  get iconCss(): EuiCss {
    return this.args.iconProps?.css;
  }

  /** Classes of an `@icon` component: upstream clones `css` and the class onto it. */
  @cached
  get iconClass(): string {
    const css = this.args.iconProps?.css;
    return [
      'euiListGroupItem__icon',
      css ? euiClass(this.context, css) : undefined
    ]
      .filter(Boolean)
      .join(' ');
  }

  /** `a` for enabled links, `button` for actions and disabled links, else `li`. */
  get kind(): 'a' | 'button' | 'li' {
    const { href, onClick } = this.args;
    if (href && !this.isDisabled) return 'a';
    if (href || onClick) return 'button';
    return 'li';
  }

  get isLink(): boolean {
    return this.kind === 'a';
  }

  get isButton(): boolean {
    return this.kind === 'button';
  }

  get isInteractive(): boolean {
    return this.kind !== 'li';
  }

  get rel(): string {
    return getSecureRelForTarget(this.args.target, this.args.rel);
  }

  get showExternal(): boolean {
    const { external, target } = this.args;
    return (
      this.isLink &&
      ((target === '_blank' && external !== false) || external === true)
    );
  }

  get newTab(): boolean {
    return this.args.target === '_blank';
  }

  get ariaCurrent(): 'true' | undefined {
    return this.isActive ? 'true' : undefined;
  }

  get showToolTip(): boolean {
    return Boolean(
      this.args.showToolTip ?? listGroupContext(this)?.showToolTips
    );
  }

  /** Upstream `shouldRenderTitle`: no native title when wrapping or when a tooltip shows it. */
  get shouldRenderTitle(): boolean {
    return !this.wrapText && !this.showToolTip;
  }

  /**
   * Upstream `title`: the label when it is a string, else its inner text.
   * A block is the Ember label node.
   */
  title = (innerText: string, hasBlock: boolean): string | undefined => {
    if (!this.shouldRenderTitle) return undefined;
    return hasBlock ? innerText : this.args.label;
  };

  /** `EuiInnerText`'s ref, only while a block label needs a title. */
  textRef = (
    ref: (element: HTMLElement) => void,
    hasBlock: boolean
  ): ((element: HTMLElement) => void) | undefined => {
    return hasBlock && this.shouldRenderTitle ? ref : undefined;
  };

  /** Id of the tooltip, for the plain `<li>`'s `aria-describedby`. */
  get toolTipId(): string {
    return this.args.toolTipProps?.id ?? `${guidFor(this)}-tooltip`;
  }

  /**
   * Whether the tooltip shows the block (upstream `content: toolTipText ??
   * label` with a node label): no `@toolTipText` and no `content` in
   * `@toolTipProps`.
   */
  blockToolTip = (hasBlock: boolean): boolean => {
    return (
      hasBlock &&
      this.args.toolTipText === undefined &&
      this.args.toolTipProps?.content === undefined
    );
  };

  /** Upstream `_tooltipProps`: label as content, shown to the right. */
  @cached
  get toolTipProps(): Partial<EuiTooltipArgs> | undefined {
    if (!this.showToolTip) return undefined;
    return {
      content: this.args.toolTipText ?? this.args.label,
      position: 'right',
      ...this.args.toolTipProps,
      id: this.toolTipId
    };
  }

  @cached
  get toolTipAnchorClass(): string {
    return `euiListGroupItem__tooltip${
      this.args.toolTipProps?.anchorClassName
        ? ` ${this.args.toolTipProps.anchorClassName}`
        : ''
    }`;
  }

  @cached
  get toolTipAnchorCss(): EuiCss {
    return [
      euiListGroupItemTooltipStyles.euiListGroupItem__tooltip,
      this.isDisabled && this.layout.tooltip.isDisabled,
      this.args.toolTipProps?.anchorCss
    ];
  }

  get extraActionComponent(): ComponentLike | undefined {
    const action = this.args.extraAction;
    return action && !isPlainObject(action) ? action : undefined;
  }

  get extraActionProps(): EuiListGroupItemExtraActionProps | undefined {
    const action = this.args.extraAction;
    return isPlainObject(action) ? action : undefined;
  }

  get hasExtraAction(): boolean {
    return Boolean(this.args.extraAction);
  }

  @cached
  get layout() {
    return useEuiBorealisStyles(this.context, euiListItemLayoutStyles);
  }

  /** Upstream `css` of the item: base, inner layout and color. */
  @cached
  get itemStyles(): CSSInterpolation[] {
    const styles = useEuiBorealisStyles(this.context, euiListGroupItemStyles);
    const color = this.color;
    let colorStyle: CSSInterpolation;
    if (color === 'inherit') colorStyle = { color: 'inherit' };
    else if (color === 'ghost') colorStyle = styles.text;
    else if (color === 'primary' || color === 'text' || color === 'subdued')
      colorStyle = styles[color];
    return [
      styles.euiListGroupItem,
      styles.euiListGroupItem__inner,
      !this.isDisabled && !this.isActive && colorStyle
    ];
  }

  /**
   * Upstream `isInteractive`/`isSelected`, skipped while disabled unless
   * `@hasAriaDisabled` (upstream `canHaveInteractiveStyles`).
   */
  @cached
  get interactiveStyles(): CSSInterpolation[] {
    if (this.isDisabled && !this.hasAriaDisabled) return [];
    return [
      this.isInteractive && this.layout.isInteractive,
      this.isActive && this.layout.isSelected
    ];
  }

  @cached
  get reset(): CSSInterpolation {
    const theme = this.context.upstream.euiTheme;
    // Scoped stand-in for React's global reset; upstream styles come after.
    return {
      boxSizing: 'border-box',
      margin: 0,
      padding: 0,
      border: 0,
      listStyle: 'none',
      background: 'none',
      fontFamily: theme.font.family,
      textDecoration: 'none'
    };
  }

  /** The `<li>` around links/buttons, which owns their hover/selected styles. */
  @cached
  get wrapperClass(): string {
    const context = this.context;
    const wrapper = useEuiBorealisStyles(context, euiListItemLayoutWrapperStyles);
    return `euiListItemLayout__wrapper ${euiClass(
      context,
      this.reset,
      wrapper.euiListItemLayout__wrapper,
      this.hasExtraAction && wrapper.hasExtraAction,
      ...this.interactiveStyles,
      ...this.itemStyles,
      this.isDisabled && this.layout.isDisabled
    )}`;
  }

  @cached
  get elementClass(): string {
    const context = this.context;
    const layout = this.layout;
    const own = this.isInteractive
      ? [
          layout.euiListItemLayout__action,
          // upstream: custom disabled buttons with a tooltip ignore the pointer
          this.isButton &&
            this.isDisabled &&
            this.hasAriaDisabled &&
            this.showToolTip &&
            layout.buttonIsDisabled
        ]
      : [...this.interactiveStyles, ...this.itemStyles];
    const kind = this.isInteractive
      ? 'euiListGroupItem__button'
      : 'euiListGroupItem__text';
    return `euiListItemLayout euiListGroupItem ${kind} ${euiClass(
      context,
      this.reset,
      layout.euiListItemLayout,
      ...own,
      this.isDisabled && layout.isDisabled
    )}`;
  }

  @cached
  get contentClass(): string {
    return `euiListItemLayout__content ${euiClass(
      this.context,
      this.layout.euiListItemLayout__content
    )}`;
  }

  @cached
  get prependClass(): string {
    return `euiListItemLayout__prepend ${euiClass(
      this.context,
      this.layout.euiListItemLayout__prepend
    )}`;
  }

  @cached
  get textClass(): string {
    const layout = this.layout;
    return `euiListItemLayout__text euiListGroupItem__label ${euiClass(
      this.context,
      layout.euiListItemLayout__text,
      layout.textWrap[this.wrapText ? 'wrap' : 'truncate']
    )}`;
  }

  @cached
  get externalIconCss(): EuiCss {
    const theme = this.context.upstream.euiTheme;
    return [
      this.layout.externalIcon,
      // Upstream EuiExternalLinkIcon margin.
      { marginInlineStart: theme.size.xs }
    ];
  }

  @cached
  get srOnlyClass(): string {
    return `euiListGroupItem__screenReaderOnly ${euiClass(
      this.context,
      euiScreenReaderOnly()
    )}`;
  }

  /** Upstream extra-action styles, then the action's own `css`. */
  @cached
  get extraActionCss(): EuiCss {
    const styles = useEuiBorealisStyles(
      this.context,
      euiListGroupItemExtraActionStyles
    );
    const alwaysShow = Boolean(this.extraActionProps?.alwaysShow);
    return [
      styles.euiListGroupItemExtraAction,
      alwaysShow && styles.alwaysShow,
      !alwaysShow && !this.isDisabled && styles.hoverStyles,
      this.extraActionProps?.css
    ];
  }

  get extraActionColor(): string {
    const color = this.extraActionProps?.color ?? this.color;
    return ['subdued', 'inherit', 'ghost'].includes(color) ? 'text' : color;
  }

  get extraActionDisabled(): boolean {
    return Boolean(this.extraActionProps?.isDisabled || this.isDisabled);
  }

  <template>
    {{#let (has-block) as |hasBlock|}}
    <EuiInnerText as |setTextRef innerText|>
    {{#if this.isInteractive}}
      <li class={{this.wrapperClass}}>
        <EuiMaybeToolTip
          @props={{this.toolTipProps}}
          @anchorClass={{this.toolTipAnchorClass}}
          @anchorCss={{this.toolTipAnchorCss}}
          @blockContent={{this.blockToolTip hasBlock}}
        >
          <:default>
            {{#if this.isLink}}
              <a
                class={{this.elementClass}}
                href={{@href}}
                target={{@target}}
                rel={{this.rel}}
                aria-current={{this.ariaCurrent}}
                {{on "click" (optional @onClick)}}
                ...attributes
              >
                <Content
                  @contentClass={{this.contentClass}}
                  @prependClass={{this.prependClass}}
                  @textClass={{this.textClass}}
                  @iconType={{@iconType}}
                  @iconProps={{@iconProps}}
                  @iconCss={{this.iconCss}}
                  @icon={{@icon}}
                  @iconClass={{this.iconClass}}
                  @title={{this.title innerText hasBlock}}
                  @textRef={{this.textRef setTextRef hasBlock}}
                  @showExternal={{this.showExternal}}
                  @newTab={{this.newTab}}
                  @externalIconCss={{this.externalIconCss}}
                  @srOnlyClass={{this.srOnlyClass}}
                >
                  {{#if hasBlock}}{{yield}}{{else}}{{@label}}{{/if}}
                </Content>
              </a>
            {{else}}
              <button
                class={{this.elementClass}}
                type="button"
                disabled={{this.nativeDisabled}}
                aria-disabled={{this.buttonAriaDisabled}}
                aria-current={{this.ariaCurrent}}
                {{euiDisabledElement this.isDisabled @hasAriaDisabled}}
                {{on "click" (optional @onClick)}}
                ...attributes
              >
                <Content
                  @contentClass={{this.contentClass}}
                  @prependClass={{this.prependClass}}
                  @textClass={{this.textClass}}
                  @iconType={{@iconType}}
                  @iconProps={{@iconProps}}
                  @iconCss={{this.iconCss}}
                  @icon={{@icon}}
                  @iconClass={{this.iconClass}}
                  @title={{this.title innerText hasBlock}}
                  @textRef={{this.textRef setTextRef hasBlock}}
                  @showExternal={{false}}
                  @newTab={{false}}
                  @externalIconCss={{this.externalIconCss}}
                  @srOnlyClass={{this.srOnlyClass}}
                >
                  {{#if hasBlock}}{{yield}}{{else}}{{@label}}{{/if}}
                </Content>
              </button>
            {{/if}}
          </:default>
          <:content>{{yield}}</:content>
        </EuiMaybeToolTip>
        {{#if this.hasExtraAction}}
          <ExtraAction
            @component={{this.extraActionComponent}}
            @props={{this.extraActionProps}}
            @css={{this.extraActionCss}}
            @color={{this.extraActionColor}}
            @disabled={{this.extraActionDisabled}}
          />
        {{/if}}
      </li>
    {{else}}
      <li
        class={{this.elementClass}}
        aria-current={{this.ariaCurrent}}
        aria-disabled={{if this.isDisabled "true"}}
        ...attributes
        {{describedByToolTip (if this.toolTipProps this.toolTipId)}}
      >
        <EuiMaybeToolTip
          @props={{this.toolTipProps}}
          @anchorClass={{this.toolTipAnchorClass}}
          @anchorCss={{this.toolTipAnchorCss}}
          @blockContent={{this.blockToolTip hasBlock}}
        >
          <:default>
            <Content
              @contentClass={{this.contentClass}}
              @prependClass={{this.prependClass}}
              @textClass={{this.textClass}}
              @iconType={{@iconType}}
              @iconProps={{@iconProps}}
              @iconCss={{this.iconCss}}
              @icon={{@icon}}
              @iconClass={{this.iconClass}}
              @title={{this.title innerText hasBlock}}
              @textRef={{this.textRef setTextRef hasBlock}}
              @showExternal={{false}}
              @newTab={{false}}
              @externalIconCss={{this.externalIconCss}}
              @srOnlyClass={{this.srOnlyClass}}
            >
              <:default>
                {{#if hasBlock}}{{yield}}{{else}}{{@label}}{{/if}}
              </:default>
              <:after>
                {{#if this.hasExtraAction}}
                  <ExtraAction
                    @component={{this.extraActionComponent}}
                    @props={{this.extraActionProps}}
                    @css={{this.extraActionCss}}
                    @color={{this.extraActionColor}}
                    @disabled={{this.extraActionDisabled}}
                  />
                {{/if}}
              </:after>
            </Content>
          </:default>
          <:content>{{yield}}</:content>
        </EuiMaybeToolTip>
      </li>
    {{/if}}
    </EuiInnerText>
    {{/let}}
  </template>
}
