import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { get } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { getTokenName } from '@elastic/eui-theme-common';
import { modifier } from 'ember-modifier';
import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, eq, or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiBorderColor,
  euiCallOutHeaderStyles,
  euiCallOutStyles
} from '../utils/eui/styles.generated.ts';
import EuiButton from './eui-button.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiIcon from './eui-icon.gts';
import EuiLiveAnnouncer from './eui-live-announcer.gts';
import EuiPanel from './eui-panel.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';
import EuiMaybeToolTip from '../-private/eui-maybe-tool-tip.gts';
import EuiMaybePopover from '../-private/eui-maybe-popover.gts';
import EuiRenderNode from '../-private/eui-render-node.gts';
import spreadAttributes from '../-private/eui-spread-attributes.ts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiIconSignature } from './eui-icon';
import type { EuiTextSignature } from './eui-text';
import type { EuiTitleSignature } from './eui-title';
import type { EuiTooltipArgs } from './eui-tool-tip.gts';
import type { EuiWithPopoverProps } from '../-private/eui-maybe-popover.gts';
import type { EuiRenderNode as EuiRenderNodeType } from '../-private/eui-render-node.gts';

export type EuiCallOutColor = 'primary' | 'success' | 'warning' | 'danger';

/**
 * Upstream `dismissButtonProps`: extra props of the dismiss
 * `EuiButtonIcon`. `iconType`, `color`, `size` and `onClick` are fixed by
 * the callout, as upstream.
 */
export interface EuiCallOutDismissButtonProps {
  /** Extra class of the button. */
  className?: string;
  /** Styles composed after the dismiss button's own (upstream `css`). */
  css?: EuiCss;
  'aria-label'?: string;
  'data-test-subj'?: string;
  isDisabled?: boolean;
  hasAriaDisabled?: boolean;
  display?: 'empty' | 'base' | 'fill';
  iconSize?: EuiIconSignature['Args']['size'];
  /** Other keys (`id`, `title`, `data-*`, …) become attributes of the button. */
  [attribute: string]: unknown;
}

/** `dismissButtonProps` keys that are args or handled by the template. */
const DISMISS_ARGS = [
  'aria-label',
  'data-test-subj',
  'isDisabled',
  'hasAriaDisabled',
  'display',
  'iconSize',
  'iconType',
  'color',
  'size',
  'onClick'
] as const;
export type EuiCallOutSize = 's' | 'm';

/**
 * An action of `@actionProps`: upstream's props for the `EuiButton`
 * (primary) or `EuiButtonEmpty` (secondary). Color and size always match
 * the callout and cannot be changed.
 */
export interface EuiCallOutActionProps {
  /** The button's text (upstream's `children`): text or a component. */
  children?: EuiRenderNodeType;
  onClick?: (event: MouseEvent) => void;
  /** Makes the action a link. */
  href?: string;
  target?: string;
  rel?: string;
  iconType?: EuiIconSignature['Args']['type'];
  iconSide?: 'left' | 'right';
  isDisabled?: boolean;
  isLoading?: boolean;
  'aria-label'?: string;
  className?: string;
  'data-test-subj'?: string;
  /** Shows a tooltip on the action: the args of `EuiToolTip`. */
  tooltipProps?: Partial<EuiTooltipArgs>;
  /**
   * Opens a popover from the action: the args of `EuiPopover` (`isOpen`,
   * `closePopover`, ...) and `children`, its content as text or a
   * component. The tooltip sits inside the popover, as upstream.
   */
  popoverProps?: EuiWithPopoverProps;
}

/**
 * Upstream's default notification icons (EuiNotificationIcon) and colors;
 * `warningStatic` has its own two-tone colors.
 */
const DEFAULT_ICONS: Record<
  EuiCallOutColor,
  { type: string; color?: string }
> = {
  primary: { type: 'infoFill', color: 'primary' },
  success: { type: 'checkCircleFill', color: 'success' },
  warning: { type: 'warningStatic' },
  danger: { type: 'errorFill', color: 'danger' }
};

const SUPER_NARROW_WIDTH = 400;
const WIDE_BREAKPOINTS: Record<EuiCallOutSize, number> = { s: 800, m: 1000 };

/**
 * Upstream's `useLayoutObserver`: sets `data-layout="superNarrow" | "wide"`
 * from the rendered width, which the actions/wrapper styles respond to.
 * The attribute is written in the next frame: changing the layout resizes
 * the callout, and writing it inside the observer callback would trigger
 * the browser's "ResizeObserver loop" error.
 */
const layoutObserver = modifier(
  (element: HTMLElement, [size]: [EuiCallOutSize]) => {
    if (typeof ResizeObserver === 'undefined') return;
    const wide = WIDE_BREAKPOINTS[size];
    let frame = 0;
    const observer = new ResizeObserver(([entry]) => {
      const width =
        entry?.borderBoxSize?.[0]?.inlineSize ??
        element.getBoundingClientRect().width;
      const layout =
        width <= SUPER_NARROW_WIDTH
          ? 'superNarrow'
          : width >= wide
            ? 'wide'
            : null;
      if (element.getAttribute('data-layout') === layout) return;
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        if (layout) element.setAttribute('data-layout', layout);
        else element.removeAttribute('data-layout');
      });
    });
    observer.observe(element);
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
    };
  }
);

/** A colored box drawing attention to a message, e.g. a warning or a success notice. */
export interface EuiCallOutSignature {
  Element: HTMLDivElement;
  Args: {
    /** Title in the callout's header. Use the `<:title>` block for markup. */
    title?: string;
    /**
     * Tag of the title, e.g. `'h2'` so it appears in the page outline:
     * `'h1'`–`'h6'` or `'p'`. Defaults to `'p'`.
     */
    heading?: EuiTitleSignature['Args']['tagName'];
    /**
     * Main text, rendered inline after the title in small callouts. Use the
     * default (or `<:body>`) block for other content.
     */
    text?: string;
    /**
     * Icon before the content, e.g. `'warning'`, `'check'` or `'question'`. Without
     * it, a default icon matching `@color` is shown.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /** `'s'` or `'m'`. Defaults to `'m'`. */
    size?: EuiCallOutSize;
    /**
     * `'primary'`, `'success'`, `'warning'` or `'danger'`. Other values fall
     * back to `'primary'`. Defaults to `'primary'`.
     */
    color?: EuiCallOutColor;
    /** Color of the body text, any `EuiText` color. Defaults to `'default'`. */
    textColor?: EuiTextSignature['Args']['color'];
    /** Size of a custom `@iconType`. Defaults to `'m'` for small callouts, `'l'` otherwise. */
    iconSize?: EuiIconSignature['Args']['size'];
    /**
     * Renders a dismiss (cross) button in the top end corner; called when it
     * is clicked.
     */
    onDismiss?: (event: MouseEvent) => void;
    /** Accessible label of the dismiss button. Defaults to "Dismiss this callout" (i18n token `euiCallOut.dismissAriaLabel`). */
    dismissButtonAriaLabel?: string;
    /**
     * Extra props of the dismiss button (upstream `dismissButtonProps`), e.g.
     * `{ 'data-test-subj': 'closeTip' }`, see `EuiCallOutDismissButtonProps`.
     */
    dismissButtonProps?: EuiCallOutDismissButtonProps;
    /**
     * Announces the title, text and body to screen readers when the callout
     * is inserted (through `EuiLiveAnnouncer`). Use it only when the callout
     * is feedback to a user action, not on page load. Defaults to `false`.
     */
    announceOnMount?: boolean;
    /**
     * Up to two actions after the content: `primary` renders as an
     * `EuiButton` and `secondary` as an `EuiButtonEmpty`, both small and in
     * the callout's color. Rendered before the `<:actions>` block.
     */
    actionProps?: {
      primary?: EuiCallOutActionProps;
      secondary?: EuiCallOutActionProps;
    };
  };
  Blocks: {
    /** The title, instead of `@title`. */
    title?: [];
    /** The body; same as the default block. */
    body?: [];
    /** The body, e.g. paragraphs or a list. */
    default?: [];
    /**
     * Actions, e.g. `<EuiButton @size="s">` and `<EuiButtonEmpty @size="s">`.
     * Laid out beside the content in wide callouts.
     */
    actions?: [];
  };
}

/** Native Ember callout on the upstream EUI 123 / Borealis factories. */
export default class EuiCallOut extends Component<EuiCallOutSignature> {
  @service declare euiI18n: EuiI18n;

  layoutObserver = layoutObserver;

  @cached
  get context() {
    return getEuiThemeContext(this);
  }

  get color(): EuiCallOutColor {
    const color = this.args.color;
    return color && Object.prototype.hasOwnProperty.call(DEFAULT_ICONS, color)
      ? color
      : 'primary';
  }

  get size(): EuiCallOutSize {
    return this.args.size === 's' ? 's' : 'm';
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiCallOutStyles);
  }

  /** Upstream: an EuiPanel with the callout's styles as its `css`. */
  @cached
  get panelCss(): EuiCss {
    const { upstream } = this.context;
    return [
      this.styles.euiCallOut,
      { borderColor: euiBorderColor(upstream, this.color) },
      this.args.onDismiss && this.styles.hasDismissButton
    ];
  }

  @cached
  get wrapperClass() {
    return euiClass(this.context, this.styles.wrapper);
  }

  @cached
  get bodyClass() {
    return euiClass(this.context, this.styles.body);
  }

  @cached
  get contentClass() {
    return euiClass(this.context, this.styles.content);
  }

  @cached
  get actionsClass() {
    return euiClass(this.context, this.styles.actions);
  }

  // Upstream's `css` on the icon and the title.
  get iconCss(): EuiCss {
    return this.styles.icon;
  }

  @cached
  get headerCss(): EuiCss {
    return useEuiBorealisStyles(this.context, euiCallOutHeaderStyles)
      .euiCallOutHeader;
  }

  /** Upstream's `css` on the dismiss EuiButtonIcon. */
  @cached
  get dismissCss(): EuiCss {
    return [
      this.styles.dismissButton.euiCallOut__dismissButton,
      this.args.dismissButtonProps?.css
    ];
  }

  get dismissTestSubj(): string {
    const own = this.args.dismissButtonProps?.['data-test-subj'];
    return own ?? 'euiDismissCalloutButton';
  }

  get titleSize(): EuiTitleSignature['Args']['size'] {
    return this.size === 's' ? 'xxs' : 'xs';
  }

  get iconSize(): EuiIconSignature['Args']['size'] {
    return this.args.iconSize ?? (this.size === 's' ? 'm' : 'l');
  }

  /** Upstream colors custom icons with the `borderStrong<Color>` token. */
  @cached
  get customIconColor(): string {
    const colors = this.context.upstream.euiTheme.colors as unknown as Record<
      string,
      string
    >;
    return colors[getTokenName('borderStrong', this.color)]!;
  }

  get defaultIcon() {
    return DEFAULT_ICONS[this.color];
  }

  get childrenSize(): EuiTextSignature['Args']['size'] {
    return this.size === 's' ? 'xs' : 's';
  }

  get textColor(): EuiTextSignature['Args']['color'] {
    return this.args.textColor ?? 'default';
  }

  get dismissLabel(): string {
    return (
      this.args.dismissButtonProps?.['aria-label'] ??
      this.args.dismissButtonAriaLabel ??
      this.euiI18n.lookupToken(
        'euiCallOut.dismissAriaLabel',
        'Dismiss this callout'
      )
    );
  }

  <template>
    <EuiPanel
      class="euiCallOut euiCallOut--{{this.color}}"
      @color={{this.color}}
      @hasBorder={{true}}
      @hasShadow={{false}}
      @paddingSize="none"
      @borderRadius="none"
      @grow={{false}}
      @css={{this.panelCss}}
      data-size={{this.size}}
      {{this.layoutObserver this.size}}
      ...attributes
    >
      <div class={{this.wrapperClass}}>
        <div class={{this.bodyClass}}>
          {{#if @iconType}}
            <EuiIcon
              @css={{this.iconCss}}
              @type={{@iconType}}
              @size={{this.iconSize}}
              @color={{this.customIconColor}}
              aria-hidden="true"
            />
          {{else}}
            <EuiIcon
              class="euiNotificationIcon"
              @css={{this.iconCss}}
              @type={{this.defaultIcon.type}}
              @size={{if (eq this.size "s") "m" "l"}}
              @color={{this.defaultIcon.color}}
              aria-hidden="true"
            />
          {{/if}}
          <div class={{this.contentClass}}>
            {{#if (or @title (has-block "title"))}}
              <EuiTitle
                @tagName={{if @heading @heading "p"}}
                @size={{this.titleSize}}
                class="euiCallOutHeader__title"
                @css={{this.headerCss}}
              >
                {{#if (has-block "title")}}
                  {{yield to="title"}}
                {{else}}
                  {{@title}}
                {{/if}}
              </EuiTitle>
              {{! After the title, so screen reader users know what it dismisses. }}
              {{#if @onDismiss}}
                <EuiButtonIcon
                  class={{@dismissButtonProps.className}}
                  data-test-subj={{this.dismissTestSubj}}
                  aria-label={{this.dismissLabel}}
                  @iconType="cross"
                  @color={{this.color}}
                  @size="xs"
                  @isDisabled={{@dismissButtonProps.isDisabled}}
                  @hasAriaDisabled={{@dismissButtonProps.hasAriaDisabled}}
                  @display={{@dismissButtonProps.display}}
                  @iconSize={{@dismissButtonProps.iconSize}}
                  @css={{this.dismissCss}}
                  {{spreadAttributes @dismissButtonProps DISMISS_ARGS}}
                  {{on "click" @onDismiss}}
                />
              {{/if}}
            {{/if}}
            {{#if @text}}
              <EuiText
                class="euiCallOut__text"
                @size="s"
                @color={{this.textColor}}
              >{{@text}}</EuiText>
            {{/if}}
            {{#if (has-block "body")}}
              <EuiText
                class="euiCallOut__additionalContent"
                @size={{this.childrenSize}}
                @color={{this.textColor}}
              >{{yield to="body"}}</EuiText>
            {{else if (has-block)}}
              <EuiText
                class="euiCallOut__additionalContent"
                @size={{this.childrenSize}}
                @color={{this.textColor}}
              >{{yield}}</EuiText>
            {{/if}}
            {{#unless (or @title (has-block "title"))}}
              {{#if @onDismiss}}
                <EuiButtonIcon
                  class={{@dismissButtonProps.className}}
                  data-test-subj={{this.dismissTestSubj}}
                  aria-label={{this.dismissLabel}}
                  @iconType="cross"
                  @color={{this.color}}
                  @size="xs"
                  @isDisabled={{@dismissButtonProps.isDisabled}}
                  @hasAriaDisabled={{@dismissButtonProps.hasAriaDisabled}}
                  @display={{@dismissButtonProps.display}}
                  @iconSize={{@dismissButtonProps.iconSize}}
                  @css={{this.dismissCss}}
                  {{spreadAttributes @dismissButtonProps DISMISS_ARGS}}
                  {{on "click" @onDismiss}}
                />
              {{/if}}
            {{/unless}}
          </div>
        </div>
        {{#if (or @actionProps.primary @actionProps.secondary (has-block "actions"))}}
          <div class={{this.actionsClass}}>
            {{#if @actionProps.primary}}
              <EuiMaybePopover @props={{@actionProps.primary.popoverProps}}><EuiMaybeToolTip @props={{@actionProps.primary.tooltipProps}}>
                <EuiButton
                  class="euiCallOutAction {{@actionProps.primary.className}}"
                  @size="s"
                  @color={{this.color}}
                  @iconType={{@actionProps.primary.iconType}}
                  @iconSide={{@actionProps.primary.iconSide}}
                  @isDisabled={{@actionProps.primary.isDisabled}}
                  @isLoading={{@actionProps.primary.isLoading}}
                  @href={{@actionProps.primary.href}}
                  @target={{@actionProps.primary.target}}
                  rel={{@actionProps.primary.rel}}
                  aria-label={{get @actionProps.primary "aria-label"}}
                  data-test-subj={{get @actionProps.primary "data-test-subj"}}
                  {{on "click" (optional @actionProps.primary.onClick)}}
                ><EuiRenderNode @value={{@actionProps.primary.children}} /></EuiButton>
              </EuiMaybeToolTip></EuiMaybePopover>
            {{/if}}
            {{#if @actionProps.secondary}}
              <EuiMaybePopover @props={{@actionProps.secondary.popoverProps}}><EuiMaybeToolTip @props={{@actionProps.secondary.tooltipProps}}>
                <EuiButtonEmpty
                  class="euiCallOutAction {{@actionProps.secondary.className}}"
                  @size="s"
                  @color={{this.color}}
                  @iconType={{@actionProps.secondary.iconType}}
                  @iconSide={{@actionProps.secondary.iconSide}}
                  @isDisabled={{@actionProps.secondary.isDisabled}}
                  @isLoading={{@actionProps.secondary.isLoading}}
                  @href={{@actionProps.secondary.href}}
                  @target={{@actionProps.secondary.target}}
                  rel={{@actionProps.secondary.rel}}
                  aria-label={{get @actionProps.secondary "aria-label"}}
                  data-test-subj={{get @actionProps.secondary "data-test-subj"}}
                  {{on "click" (optional @actionProps.secondary.onClick)}}
                ><EuiRenderNode @value={{@actionProps.secondary.children}} /></EuiButtonEmpty>
              </EuiMaybeToolTip></EuiMaybePopover>
            {{/if}}
            {{yield to="actions"}}
          </div>
        {{/if}}
      </div>
      {{#if @announceOnMount}}
        {{#if (or @title (has-block "title") @text (has-block "body") (has-block))}}
          {{! Upstream: title, text and children joined by ",&nbsp;". }}
          <EuiLiveAnnouncer>{{#if (has-block "title")}}{{yield to="title"}}{{else}}{{@title}}{{/if}}{{#if
                (and (or @title (has-block "title")) @text)
              }},&nbsp;{{/if}}{{@text}}{{#if
                (and
                  (or @title (has-block "title") @text)
                  (or (has-block "body") (has-block))
                )
              }},&nbsp;{{/if}}{{#if (has-block "body")}}{{yield to="body"}}{{else if (has-block)}}{{yield}}{{/if}}</EuiLiveAnnouncer>
        {{/if}}
      {{/if}}
    </EuiPanel>
  </template>
}
