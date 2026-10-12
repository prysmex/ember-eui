import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { and, not } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiContextMenuItemStyles,
  euiListItemLayoutStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type { EuiIconSignature } from './eui-icon';

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
    /** Shows a spinner instead of the icon. */
    isLoading?: boolean;
    /**
     * Icon before the text; anything `EuiIcon`'s `@type` accepts. Pass
     * `'empty'` to align items without an icon with the others.
     */
    icon?: EuiIconSignature['Args']['type'];
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
  };

  Blocks: {
    /** The item's text. */
    default: [];
  };
}

export default class EuiContextMenuItemComponent extends Component<EuiContextMenuItemSignature> {
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
    const color = this.args.color ?? 'text';

    return `euiContextMenuItem euiListItemLayout ${euiClass(
      context,
      ITEM_RESET,
      layout.euiListItemLayout,
      !disabled && layout.isInteractive,
      styles.euiContextMenuItem,
      styles.layoutAlign[this.args.layoutAlign ?? 'center'],
      !disabled && color !== 'text' && styles.colors[color],
      disabled && layout.isDisabled
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
      // EuiIcon/EuiLoadingSpinner are migrated children: no second Emotion
      // class on them (rule precedence would depend on insertion order).
      // Upstream `euiContextMenu__icon` (flex-shrink: 0) is already EuiIcon's
      // own style; `euiContextMenuItem__arrow` (align-self: flex-end) waits
      // for EuiIcon's `@css` (see overlays-handoff.md).
      icon: 'euiContextMenu__icon',
      arrow: 'euiContextMenu__arrow'
    };
  }

  get iconClasses(): string {
    return [this.parts.icon, this.args.iconClasses].filter(Boolean).join(' ');
  }

  <template>
    {{#if @toolTipContent}}
      <EuiToolTip
        @content={{@toolTipContent}}
        @title={{@toolTipTitle}}
        @position="right"
        @display="block"
      >
        {{#if (and @href (not @disabled))}}
          <a
            class={{this.classes}}
            href={{@href}}
            target={{@target}}
            {{didInsert this.registerLink}}
            ...attributes
          />
        {{else}}
          <button
            class={{this.classes}}
            disabled={{@disabled}}
            type="button"
            {{didInsert this.registerLink}}
            ...attributes
          />
        {{/if}}
      </EuiToolTip>
    {{else if (and @href (not @disabled))}}
      <a
        class={{this.classes}}
        href={{@href}}
        target={{@target}}
        {{didInsert this.registerLink}}
        ...attributes
      />
    {{else}}
      <button
        class={{this.classes}}
        disabled={{@disabled}}
        type="button"
        {{didInsert this.registerLink}}
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
              <EuiLoadingSpinner class={{this.parts.icon}} />
            </span>
          {{else if @icon}}
            <span class={{this.parts.prepend}}>
              <EuiIcon
                @iconClasses={{this.iconClasses}}
                @type={{@icon}}
                @size="m"
                @color="inherit"
              />
            </span>
          {{/if}}
          <span class={{this.parts.text}}>
            {{yield}}
          </span>
          {{#if @hasPanel}}
            <span class={{this.parts.append}}>
              <EuiIcon
                @type="arrowRight"
                @size="m"
                @iconClasses={{this.parts.arrow}}
              />
            </span>
          {{/if}}
        </span>
      {{/in-element}}
    {{/if}}
  </template>
}
