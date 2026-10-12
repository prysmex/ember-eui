import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { getTokenName } from '@elastic/eui-theme-common';
import { modifier } from 'ember-modifier';
import { eq, or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiBorderColor,
  euiCallOutHeaderStyles,
  euiCallOutStyles
} from '../utils/eui/styles.generated.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiIcon from './eui-icon.gts';
import EuiPanel from './eui-panel.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiIconSignature } from './eui-icon';
import type { EuiTextSignature } from './eui-text';
import type { EuiTitleSignature } from './eui-title';

export type EuiCallOutColor = 'primary' | 'success' | 'warning' | 'danger';
export type EuiCallOutSize = 's' | 'm';

/**
 * Upstream's default notification icons (`infoFill`, `checkCircleFill`,
 * `warningStatic`, `errorFill`) are not in Ember's icon set yet; these are
 * the closest available glyphs, with upstream's colors.
 */
const DEFAULT_ICONS: Record<
  EuiCallOutColor,
  { type: string; color?: string }
> = {
  primary: { type: 'iInCircle', color: 'primary' },
  success: { type: 'checkInCircleFilled', color: 'success' },
  warning: { type: 'warning', color: 'warning' },
  danger: { type: 'error', color: 'danger' }
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
     * Icon before the content, e.g. `'alert'`, `'check'` or `'help'`. Without
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
    return this.styles.dismissButton.euiCallOut__dismissButton;
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
                  data-test-subj="euiDismissCalloutButton"
                  aria-label={{this.dismissLabel}}
                  @iconType="cross"
                  @color={{this.color}}
                  @size="xs"
                  @css={{this.dismissCss}}
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
                  data-test-subj="euiDismissCalloutButton"
                  aria-label={{this.dismissLabel}}
                  @iconType="cross"
                  @color={{this.color}}
                  @size="xs"
                  @css={{this.dismissCss}}
                  {{on "click" @onDismiss}}
                />
              {{/if}}
            {{/unless}}
          </div>
        </div>
        {{#if (has-block "actions")}}
          <div class={{this.actionsClass}}>
            {{yield to="actions"}}
          </div>
        {{/if}}
      </div>
    </EuiPanel>
  </template>
}
