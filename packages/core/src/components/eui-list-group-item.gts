import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { get } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import { listGroupContext } from '../-private/eui-list-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiListGroupItemExtraActionStyles,
  euiListGroupItemStyles,
  euiListItemLayoutStyles,
  euiListItemLayoutWrapperStyles,
  euiScreenReaderOnly
} from '../utils/eui/styles.generated.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiIcon from './eui-icon.gts';
import { getSecureRelForTarget, isValidHref } from './eui-link.gts';

import type { EuiButtonIconSignature } from './eui-button-icon';
import type { EuiIconSignature } from './eui-icon';
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
    /** Highlights the item and sets `aria-current`, e.g. the current page. */
    isActive?: boolean;
    /** Disables the item. A disabled link renders a disabled `<button>`. */
    isDisabled?: boolean;
    /**
     * Wraps long text instead of truncating it. Defaults to the list's
     * `@wrapText`, else `false`.
     */
    wrapText?: boolean;
    /**
     * Rendered after the item: upstream's props object for an
     * `EuiButtonIcon` (`{ iconType, alwaysShow, onClick, 'aria-label', … }`),
     * or any component (use `(component …)`).
     */
    extraAction?: ComponentLike | EuiListGroupItemExtraActionProps;
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
    /** Custom content instead of `@label`. */
    default: [];
  };
}

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
    title?: string;
    showExternal: boolean;
    newTab: boolean;
    externalIconCss: EuiCss;
    srOnlyClass: string;
  };
  Blocks: { default: []; after: [] };
}

const Content: TemplateOnlyComponent<ContentSignature> = <template>
  <span class={{@contentClass}}>
    {{#if @iconType}}
      <span class={{@prependClass}}>
        <EuiIcon
          class="euiListGroupItem__icon"
          @type={{@iconType}}
          @color="inherit"
        />
      </span>
    {{/if}}
    <span class={{@textClass}} title={{@title}}>
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

  get wrapText(): boolean {
    return Boolean(this.args.wrapText ?? listGroupContext(this)?.wrapText);
  }

  get isDisabled(): boolean {
    const { href, isDisabled } = this.args;
    return Boolean(isDisabled || (href && !isValidHref(href)));
  }

  get isActive(): boolean {
    return Boolean(this.args.isActive);
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

  get title(): string | undefined {
    return this.wrapText ? undefined : this.args.label;
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

  /** Upstream `isInteractive`/`isSelected`, skipped while disabled. */
  @cached
  get interactiveStyles(): CSSInterpolation[] {
    if (this.isDisabled) return [];
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
      ? [layout.euiListItemLayout__action]
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
    {{#if this.isInteractive}}
      <li class={{this.wrapperClass}}>
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
              @title={{this.title}}
              @showExternal={{this.showExternal}}
              @newTab={{this.newTab}}
              @externalIconCss={{this.externalIconCss}}
              @srOnlyClass={{this.srOnlyClass}}
            >
              {{#if (has-block)}}{{yield}}{{else}}{{@label}}{{/if}}
            </Content>
          </a>
        {{else}}
          <button
            class={{this.elementClass}}
            type="button"
            disabled={{this.isDisabled}}
            aria-current={{this.ariaCurrent}}
            {{on "click" (optional @onClick)}}
            ...attributes
          >
            <Content
              @contentClass={{this.contentClass}}
              @prependClass={{this.prependClass}}
              @textClass={{this.textClass}}
              @iconType={{@iconType}}
              @title={{this.title}}
              @showExternal={{false}}
              @newTab={{false}}
              @externalIconCss={{this.externalIconCss}}
              @srOnlyClass={{this.srOnlyClass}}
            >
              {{#if (has-block)}}{{yield}}{{else}}{{@label}}{{/if}}
            </Content>
          </button>
        {{/if}}
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
      >
        <Content
          @contentClass={{this.contentClass}}
          @prependClass={{this.prependClass}}
          @textClass={{this.textClass}}
          @iconType={{@iconType}}
          @title={{this.title}}
          @showExternal={{false}}
          @newTab={{false}}
          @externalIconCss={{this.externalIconCss}}
          @srOnlyClass={{this.srOnlyClass}}
        >
          <:default>
            {{#if (has-block)}}{{yield}}{{else}}{{@label}}{{/if}}
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
      </li>
    {{/if}}
  </template>
}
