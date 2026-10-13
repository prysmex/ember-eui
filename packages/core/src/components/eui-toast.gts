import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { getTokenName } from '@elastic/eui-theme-common';
import { and, or } from 'ember-truth-helpers';

import EuiRenderNode, { isTextNode } from '../-private/eui-render-node.gts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiNotificationIconStyles,
  euiToastHeaderStyles,
  euiToastStyles
} from '../utils/eui/styles.generated.ts';
import EuiButton from './eui-button.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiIcon from './eui-icon.gts';
import EuiTitle from './eui-title.gts';
import EuiMarkdownFormat from './eui-markdown-format.gts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';
import EuiText from './eui-text.gts';

import type { EuiRenderNode as EuiRenderNodeType } from '../-private/eui-render-node.gts';
import type EuiI18n from '../services/eui-i18n';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiIconSignature } from './eui-icon';

export type EuiToastColor = 'primary' | 'success' | 'warning' | 'danger';

/** One action button of a toast (upstream `actionProps.primary/secondary`). */
export interface EuiToastAction {
  /** The button's text. */
  children: string;
  /** Called when the button is clicked. */
  onClick?: (event: MouseEvent) => void;
  /** Makes the button a link. */
  href?: string;
  /** `data-test-subj` of the button. */
  'data-test-subj'?: string;
}

export interface IEuiToast {
  /** The title of the toast. */
  title?: string;
  /**
   * The body of the toast (markdown with `useMarkdownFormat`); upstream
   * calls it `text`. Text, or a component for rich content (a template-only
   * component or `(component Foo arg=…)`), e.g. from the `euiToaster`
   * service, which cannot pass blocks. Markdown needs text.
   */
  body?: string | EuiRenderNodeType;
  /**
   * `'primary'`, `'success'`, `'warning'` or `'danger'`: the highlight bar
   * and default icon. `'none'` (Ember only) renders a neutral toast without
   * a highlight or default icon. Defaults to `'primary'`.
   */
  color?: EuiToastColor | 'none';
  /**
   * Icon before the content, e.g. `'check'` or `'warning'`, colored like the
   * highlight. Without it, a notification icon matching `@color` is shown.
   */
  iconType?: EuiIconSignature['Args']['type'];
  /** Shows a dismiss (cross) button calling this function. */
  onClose?: () => void;
  /** Renders `body` as markdown (EuiMarkdownFormat). */
  useMarkdownFormat?: boolean;
  /**
   * Action buttons below the content: `primary` renders an `EuiButton`,
   * `secondary` an `EuiButtonEmpty`, both small and in the toast's color.
   */
  actionProps?: { primary?: EuiToastAction; secondary?: EuiToastAction };
}

/**
 * A notification card. Usually shown through the `euiToaster` service and
 * EuiGlobalToastList rather than rendered directly.
 */
export interface EuiToastSignature {
  Element: HTMLDivElement;
  Args: IEuiToast & {
    /**
     * Duration of the highlight bar's countdown animation, in ms (set by
     * EuiGlobalToastList to the toast's lifetime). Runs only when motion is
     * allowed (`prefers-reduced-motion: no-preference`).
     */
    animationMs?: number;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** Extra content below the body text. */
    default: [];
  };
}

/**
 * Upstream's default notification icons (EuiNotificationIcon) and colors,
 * as in EuiCallOut; `warningStatic` has its own two-tone colors.
 */
const DEFAULT_ICONS: Record<EuiToastColor, { type: string; color?: string }> =
  {
    primary: { type: 'infoFill', color: 'primary' },
    success: { type: 'checkCircleFill', color: 'success' },
    warning: { type: 'warningStatic' },
    danger: { type: 'errorFill', color: 'danger' }
  };

const isText = isTextNode;

/** Native Ember toast on the upstream EUI 123 / Borealis factories. */
export default class EuiToast extends Component<EuiToastSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiToastStyles);
  }

  get color(): EuiToastColor | 'none' {
    const color = this.args.color;
    if (color === 'none') return 'none';
    return color && Object.prototype.hasOwnProperty.call(DEFAULT_ICONS, color)
      ? color
      : 'primary';
  }

  /** Upstream's `borderStrong<Color>` highlight token. */
  @cached
  get typeColor(): string {
    if (this.color === 'none') return 'transparent';
    const colors = this.context.upstream.euiTheme.colors as unknown as Record<
      string,
      string
    >;
    return colors[getTokenName('borderStrong', this.color)]!;
  }

  @cached
  get classes(): string {
    const colors = this.context.upstream.euiTheme.colors as unknown as Record<
      string,
      string
    >;
    const color = this.color;
    const animationMs = this.args.animationMs;
    // Upstream sets these as inline custom properties; a class keeps the
    // caller's `style` attribute intact.
    const variables: Record<string, string> = {
      '--euiToastTypeColor': this.typeColor,
      '--euiToastTypeBackgroundColor':
        color === 'none'
          ? 'transparent'
          : colors[getTokenName('backgroundLight', color)]!
    };
    if (animationMs) variables['--euiToastAnimationMs'] = `${animationMs}ms`;
    return euiClass(
      this.context,
      { boxSizing: 'border-box' },
      this.styles.euiToast,
      variables,
      this.args.css
    );
  }

  @cached
  get decorClass(): string {
    return euiClass(
      this.context,
      this.styles.decor,
      Boolean(this.args.animationMs) && this.styles.hasAnimation
    );
  }

  @cached
  get srOnlyClass(): string {
    return euiScreenReaderOnlyClass(this.context);
  }

  @cached
  get wrapperClass(): string {
    return euiClass(this.context, this.styles.wrapper);
  }

  @cached
  get bodyClass(): string {
    return euiClass(this.context, this.styles.body);
  }

  @cached
  get contentClass(): string {
    return euiClass(this.context, this.styles.content);
  }

  @cached
  get textClass(): string {
    return euiClass(this.context, this.styles.text);
  }

  @cached
  get actionsClass(): string {
    return euiClass(this.context, this.styles.actions);
  }

  /** Upstream renders EuiTitle size `xs` with the header styles as `css`. */
  @cached
  get headerCss(): EuiCss {
    const header = useEuiBorealisStyles(this.context, euiToastHeaderStyles);
    return [header.euiToastHeader, this.args.onClose && header.hasDismissButton];
  }

  /** Icon styles composed into EuiIcon's own class (`@css`). */
  @cached
  get iconCss(): EuiCss {
    const icon = useEuiBorealisStyles(this.context, euiNotificationIconStyles);
    return [
      this.styles.icon,
      !this.args.iconType && icon.euiNotificationIcon,
      icon.size.l
    ];
  }

  get dismissCss(): EuiCss {
    return this.styles.dismissButton;
  }

  get defaultIcon() {
    return this.color === 'none' ? undefined : DEFAULT_ICONS[this.color];
  }

  /** Action buttons need a named button color. */
  get actionColor(): string {
    return this.color === 'none' ? 'text' : this.color;
  }

  /** `@body` as text, for markdown. */
  get bodyText(): string {
    return isTextNode(this.args.body) ? String(this.args.body) : '';
  }

  get dismissLabel(): string {
    return this.euiI18n.lookupToken('euiToast.dismissToast', 'Dismiss toast');
  }

  get newNotificationText(): string {
    return this.euiI18n.lookupToken(
      'euiToast.newNotification',
      'A new notification appears'
    );
  }

  <template>
    <div class="euiToast euiToast--{{this.color}} {{this.classes}}" ...attributes>
      <div class="euiToastDecor {{this.decorClass}}" role="presentation"></div>
      <p class={{this.srOnlyClass}}>{{this.newNotificationText}}</p>
      <div class={{this.wrapperClass}}>
        <div class={{this.bodyClass}}>
          {{#if @iconType}}
            <EuiIcon
              @type={{@iconType}}
              @size="l"
              @color={{this.typeColor}}
              @css={{this.iconCss}}
              aria-hidden="true"
            />
          {{else if this.defaultIcon}}
            <EuiIcon
              class="euiNotificationIcon"
              @type={{this.defaultIcon.type}}
              @size="l"
              @color={{this.defaultIcon.color}}
              @css={{this.iconCss}}
              aria-hidden="true"
            />
          {{/if}}
          <div class={{this.contentClass}}>
            {{#if @title}}
              <EuiTitle
                class="euiToastHeader__title"
                data-test-subj="euiToastHeader__title"
                @tagName="p"
                @size="xs"
                @css={{this.headerCss}}
              >{{@title}}</EuiTitle>
            {{/if}}
            {{! Upstream DOM order: the dismiss button follows the title, so
              screen reader users know what it dismisses. }}
            {{#if (and @title @onClose)}}
              <EuiButtonIcon
                @iconType="cross"
                @color="text"
                @size="xs"
                @css={{this.dismissCss}}
                aria-label={{this.dismissLabel}}
                data-test-subj="toastCloseButton"
                {{on "click" this.onDismiss}}
              />
            {{/if}}
            {{#if (or @body (has-block))}}
              <div class={{this.textClass}} data-test-subj="euiToastBody">
                {{#if @body}}
                  {{#if (and @useMarkdownFormat (isText @body))}}
                    <div class="euiToast__text" data-test-subj="euiToastText">
                      <EuiMarkdownFormat @textSize="s" @value={{this.bodyText}} />
                    </div>
                  {{else}}
                    <EuiText
                      class="euiToast__text"
                      @size="s"
                      @color="default"
                      data-test-subj="euiToastText"
                    ><EuiRenderNode @value={{@body}} /></EuiText>
                  {{/if}}
                {{/if}}
                {{#if (has-block)}}
                  <EuiText
                    class="euiToast__additionalContent"
                    @size="s"
                    @color="default"
                    data-test-subj="euiToastAdditionalContent"
                  >{{yield}}</EuiText>
                {{/if}}
              </div>
            {{/if}}
            {{#if (and @onClose (if @title false true))}}
              <EuiButtonIcon
                @iconType="cross"
                @color="text"
                @size="xs"
                @css={{this.dismissCss}}
                aria-label={{this.dismissLabel}}
                data-test-subj="toastCloseButton"
                {{on "click" this.onDismiss}}
              />
            {{/if}}
          </div>
        </div>
        {{#if (or @actionProps.primary @actionProps.secondary)}}
          <div class={{this.actionsClass}}>
            {{#if @actionProps.primary}}
              <EuiButton
                @size="s"
                @color={{this.actionColor}}
                @href={{@actionProps.primary.href}}
                data-test-subj={{@actionProps.primary.data-test-subj}}
                {{on "click" this.onPrimary}}
              >{{@actionProps.primary.children}}</EuiButton>
            {{/if}}
            {{#if @actionProps.secondary}}
              <EuiButtonEmpty
                @size="s"
                @color={{this.actionColor}}
                @href={{@actionProps.secondary.href}}
                data-test-subj={{@actionProps.secondary.data-test-subj}}
                {{on "click" this.onSecondary}}
              >{{@actionProps.secondary.children}}</EuiButtonEmpty>
            {{/if}}
          </div>
        {{/if}}
      </div>
    </div>
  </template>

  onDismiss = (): void => {
    this.args.onClose?.();
  };

  onPrimary = (event: MouseEvent): void => {
    this.args.actionProps?.primary?.onClick?.(event);
  };

  onSecondary = (event: MouseEvent): void => {
    this.args.actionProps?.secondary?.onClick?.(event);
  };
}
