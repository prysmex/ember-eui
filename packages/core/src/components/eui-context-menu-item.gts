import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { service } from '@ember/service';

import { and, not } from 'ember-truth-helpers';

import euiDisabledElement from '../-private/eui-disabled-element.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiContextMenuItemStyles,
  euiListItemLayoutStyles,
  euiScreenReaderOnly
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import { getSecureRelForTarget } from './eui-link.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiIconSignature } from './eui-icon';
import type { EuiTooltipArgs } from './eui-tool-tip';
import type { ComponentLike } from '@glint/template';

/** Scoped button/link reset (no React global reset); upstream rules follow. */
const ITEM_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none',
  background: 'none',
  font: 'inherit',
  textDecoration: 'none',
  textAlign: 'start'
} as const;

/**
 * An action in a menu, usually inside an `EuiContextMenuPanel` in an
 * `EuiPopover`. Add `{{on "click" …}}` for the action.
 */
export interface EuiContextMenuItemSignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    /**
     * @deprecated Upstream will always center. Vertical alignment of the
     * icon with the text: `'center'`, `'top'` or `'bottom'`. Defaults to
     * `'center'`.
     */
    layoutAlign?: 'center' | 'top' | 'bottom';
    /** Disables the item. */
    disabled?: boolean;
    /**
     * @deprecated Has no effect: latest EUI has a single item size.
     */
    size?: 's' | 'm';
    /** Renders the item as a link. */
    href?: string;
    /** `target` of the `@href` link, e.g. `'_blank'`. */
    target?: string;
    /**
     * `rel` of the `@href` link; `noreferrer` (and `noopener` for
     * `'_blank'`) is added, as upstream.
     */
    rel?: string;
    /**
     * Shows the external link icon after the text of an `@href` link.
     * Defaults to `true` when `@target` is `'_blank'`.
     */
    external?: boolean;
    /**
     * With `@disabled`, keeps the item focusable and sets `aria-disabled`
     * instead of `disabled` (e.g. so its tooltip still shows); clicks and
     * key presses are blocked.
     */
    hasAriaDisabled?: boolean;
    /** Shows a spinner instead of the icon. */
    isLoading?: boolean;
    /**
     * Icon before the text: an icon type name for `EuiIcon` (pass
     * `'empty'` to align items without an icon with the others), or a
     * component rendered as is, with the item's icon class and styles
     * (e.g. `(component EuiIcon type="check" color="success" size="l")`).
     */
    icon?: EuiIconSignature['Args']['type'] | ComponentLike<any>;
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** Shows an arrow on the right, for items opening another panel. */
    hasPanel?: boolean;
    /**
     * Color of the text and icon: `'text'` (default) or a button color
     * such as `'danger'` (upstream recommends `'text'` and `'danger'`).
     */
    color?: string;
    /** Shows a tooltip on the right of the item on hover and focus. */
    toolTipContent?: string;
    /** Title of the `@toolTipContent` tooltip. */
    toolTipTitle?: string;
    /**
     * More args for the tooltip, any `EuiToolTip` arg except `content`
     * (`title`, `delay`, `offset`, `anchorClassName`, `css`, …). The
     * position is always `'right'`, as upstream.
     */
    toolTipProps?: Partial<Omit<EuiTooltipArgs, 'content'>>;
  };

  Blocks: {
    /** The item's text. */
    default: [];
  };
}

export default class EuiContextMenuItemComponent extends Component<EuiContextMenuItemSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked link: HTMLAnchorElement | HTMLButtonElement | null = null;

  @action
  registerLink(e: HTMLAnchorElement | HTMLButtonElement) {
    this.link = e;
  }

  willDestroy() {
    super.willDestroy();

    this.link = null;
  }

  /**
   * Upstream renders the item through the internal `EuiListItemLayout`
   * (interactive, no indicator, wrapping text) with the context menu item
   * styles composed after it.
   */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const layout = useEuiBorealisStyles(context, euiListItemLayoutStyles);
    const styles = useEuiBorealisStyles(context, euiContextMenuItemStyles);
    const disabled = !!this.args.disabled;
    const hasAriaDisabled = !!this.args.hasAriaDisabled;
    const color = this.args.color ?? 'text';

    return `euiContextMenuItem euiListItemLayout ${euiClass(
      context,
      ITEM_RESET,
      layout.euiListItemLayout,
      // upstream `canHaveInteractiveStyles`
      (!disabled || hasAriaDisabled) && layout.isInteractive,
      styles.euiContextMenuItem,
      styles.layoutAlign[this.args.layoutAlign ?? 'center'],
      !disabled && color !== 'text' && styles.colors[color],
      disabled && layout.isDisabled,
      disabled &&
        hasAriaDisabled &&
        Boolean(this.args.toolTipContent) &&
        layout.buttonIsDisabled
    )}`;
  }

  @cached
  get parts(): {
    content: string;
    prepend: string;
    text: string;
    append: string;
    icon: string;
    arrow: string;
  } {
    const context = getEuiThemeContext(this);
    const layout = useEuiBorealisStyles(context, euiListItemLayoutStyles);
    const styles = useEuiBorealisStyles(context, euiContextMenuItemStyles);

    return {
      content: `euiListItemLayout__content ${euiClass(context, layout.euiListItemLayout__content)}`,
      prepend: `euiListItemLayout__prepend ${euiClass(context, layout.euiListItemLayout__prepend)}`,
      text: `euiListItemLayout__text euiContextMenuItem__text ${euiClass(
        context,
        layout.euiListItemLayout__text,
        layout.textWrap.wrap,
        styles.text.euiContextMenuItem__text
      )}`,
      append: `euiListItemLayout__append ${euiClass(context, layout.euiListItemLayout__append)}`,
      icon: 'euiContextMenu__icon',
      arrow: 'euiContextMenu__arrow'
    };
  }

  /**
   * Upstream's `css` on the icon/spinner (`euiContextMenu__icon`) and the
   * panel arrow (`euiContextMenuItem__arrow`), composed into the children's
   * own classes.
   */
  @cached
  get childCss(): { icon: EuiCss; arrow: EuiCss } {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiContextMenuItemStyles);
    return {
      icon: styles.euiContextMenu__icon,
      arrow: styles.euiContextMenuItem__arrow
    };
  }

  get iconClasses(): string {
    return [this.parts.icon, this.args.iconClasses].filter(Boolean).join(' ');
  }

  get iconIsType(): boolean {
    return typeof this.args.icon === 'string';
  }

  /** Classes for an icon given as a component (upstream clones `css` onto it). */
  @cached
  get elementIconClasses(): string {
    const context = getEuiThemeContext(this);
    return [
      this.iconClasses,
      euiClass(context, this.childCss.icon)
    ].join(' ');
  }

  get isLink(): boolean {
    return Boolean(this.args.href && !this.args.disabled);
  }

  get rel(): string {
    return getSecureRelForTarget(this.args.target, this.args.rel);
  }

  /** Native `disabled`, unless `@hasAriaDisabled` swaps it for `aria-disabled`. */
  get nativeDisabled(): boolean | undefined {
    return this.args.hasAriaDisabled ? undefined : this.args.disabled;
  }

  get ariaDisabled(): 'true' | undefined {
    return this.args.hasAriaDisabled && this.args.disabled ? 'true' : undefined;
  }

  /** Upstream `EuiExternalLinkIcon` in the text of an enabled link. */
  get showExternal(): boolean {
    const { external, target } = this.args;
    return (
      this.isLink &&
      ((target === '_blank' && external !== false) || external === true)
    );
  }

  get externalText(): string {
    return this.args.target === '_blank'
      ? this.euiI18n.lookupToken(
          'euiExternalLinkIcon.newTarget.screenReaderOnlyText',
          '(external, opens in a new tab or window)'
        )
      : this.euiI18n.lookupToken(
          'euiExternalLinkIcon.externalTarget.screenReaderOnlyText',
          '(external)'
        );
  }

  /** Upstream `EuiExternalLinkIcon` margin plus the layout's `externalIcon`. */
  @cached
  get externalIconCss(): EuiCss {
    const context = getEuiThemeContext(this);
    const layout = useEuiBorealisStyles(context, euiListItemLayoutStyles);
    return [
      { marginInlineStart: context.upstream.euiTheme.size.xs },
      layout.externalIcon
    ];
  }

  @cached
  get srOnlyClass(): string {
    return euiClass(getEuiThemeContext(this), euiScreenReaderOnly());
  }

  get toolTipAnchorClass(): string {
    return ['eui-displayBlock', this.args.toolTipProps?.anchorClassName]
      .filter(Boolean)
      .join(' ');
  }

  <template>
    {{#if @toolTipContent}}
      <EuiToolTip
        @title={{if @toolTipProps.title @toolTipProps.title @toolTipTitle}}
        @id={{@toolTipProps.id}}
        @delay={{@toolTipProps.delay}}
        @offset={{@toolTipProps.offset}}
        @disableScreenReaderOutput={{@toolTipProps.disableScreenReaderOutput}}
        @attachTo={{@toolTipProps.attachTo}}
        @isShown={{@toolTipProps.isShown}}
        @hasTitle={{@toolTipProps.hasTitle}}
        @onMouseOut={{@toolTipProps.onMouseOut}}
        @onFocus={{@toolTipProps.onFocus}}
        @onBlur={{@toolTipProps.onBlur}}
        @css={{@toolTipProps.css}}
        @anchorCss={{@toolTipProps.anchorCss}}
        @anchorClassName={{this.toolTipAnchorClass}}
        @display={{if @toolTipProps.display @toolTipProps.display "block"}}
        @className={{@toolTipProps.className}}
        @content={{@toolTipContent}}
        @position="right"
      >
        {{#if (and @href (not @disabled))}}
          <a
            class={{this.classes}}
            href={{@href}}
            target={{@target}}
            rel={{this.rel}}
            {{didInsert this.registerLink}}
            ...attributes
          />
        {{else}}
          <button
            class={{this.classes}}
            disabled={{this.nativeDisabled}}
            aria-disabled={{this.ariaDisabled}}
            type="button"
            {{didInsert this.registerLink}}
            {{euiDisabledElement @disabled @hasAriaDisabled}}
            ...attributes
          />
        {{/if}}
      </EuiToolTip>
    {{else if (and @href (not @disabled))}}
      <a
        class={{this.classes}}
        href={{@href}}
        target={{@target}}
        rel={{this.rel}}
        {{didInsert this.registerLink}}
        ...attributes
      />
    {{else}}
      <button
        class={{this.classes}}
        disabled={{this.nativeDisabled}}
        aria-disabled={{this.ariaDisabled}}
        type="button"
        {{didInsert this.registerLink}}
        {{euiDisabledElement @disabled @hasAriaDisabled}}
        ...attributes
      />
    {{/if}}

    {{! shared content rendered inside the button or anchor }}
    {{#if this.link}}
      {{#in-element this.link}}
        <span class={{this.parts.content}}>
          {{#if @isLoading}}
            <span class={{this.parts.prepend}}>
              {{! spinner is not part of eui spec }}
              <EuiLoadingSpinner
                class={{this.parts.icon}}
                @css={{this.childCss.icon}}
              />
            </span>
          {{else if @icon}}
            <span class={{this.parts.prepend}}>
              {{#if this.iconIsType}}
                <EuiIcon
                  @iconClasses={{this.iconClasses}}
                  @css={{this.childCss.icon}}
                  @type={{@icon}}
                  @size="m"
                  @color="inherit"
                />
              {{else}}
                <@icon class={{this.elementIconClasses}} />
              {{/if}}
            </span>
          {{/if}}
          <span class={{this.parts.text}}>
            {{yield}}
            {{#if this.showExternal}}
              <EuiIcon
                @type="external"
                @size="m"
                @css={{this.externalIconCss}}
                role="presentation"
              />
              <span class={{this.srOnlyClass}}>{{this.externalText}}</span>
            {{/if}}
          </span>
          {{#if @hasPanel}}
            <span class={{this.parts.append}}>
              <EuiIcon
                @type="chevronSingleRight"
                @size="m"
                @iconClasses={{this.parts.arrow}}
                @css={{this.childCss.arrow}}
              />
            </span>
          {{/if}}
        </span>
      {{/in-element}}
    {{/if}}
  </template>
}
