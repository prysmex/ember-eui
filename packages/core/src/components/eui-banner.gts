import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { and, or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiBackgroundColor,
  euiBannerStyles
} from '../utils/eui/styles.generated.ts';
import EuiButton from './eui-button.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiLiveAnnouncer from './eui-live-announcer.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiButtonIconSignature } from './eui-button-icon';
import type { EuiIconSignature } from './eui-icon';

export type EuiBannerSize = 's' | 'm';
export type EuiBannerColor = 'highlighted' | 'plain';
export type EuiBannerHeadingElement = 'h2' | 'h3' | 'h4' | 'h5' | 'h6';

/** One action button of a banner (upstream `actionProps.primary/secondary`). */
export interface EuiBannerAction {
  /** The button's text. */
  children: string;
  /** Called when the button is clicked. */
  onClick?: (event: MouseEvent) => void;
  /** Makes the button a link. */
  href?: string;
  /** `target` of a link button. */
  target?: string;
  /** Icon before the text. */
  iconType?: EuiIconSignature['Args']['type'];
  /** Disables the button. */
  isDisabled?: boolean;
  /** Shows a spinner and disables the button. */
  isLoading?: boolean;
  /** `data-test-subj` of the button. */
  'data-test-subj'?: string;
}

/** Upstream `dismissButtonProps`, for the dismiss `EuiButtonIcon`. */
export interface EuiBannerDismissButtonProps {
  /** Accessible label; defaults to `Dismiss "{title}" announcement`. */
  'aria-label'?: string;
  'data-test-subj'?: string;
  size?: EuiButtonIconSignature['Args']['size'];
  iconSize?: EuiButtonIconSignature['Args']['iconSize'];
  isDisabled?: boolean;
  /** Styles composed after the banner's dismiss styles. */
  css?: EuiCss;
}

/**
 * A prominent announcement inside a page, e.g. a new feature or a
 * promotion, with an illustration, a title, text, optional actions and an
 * optional dismiss button (upstream `EuiBanner`). The layout adapts to the
 * banner's own width (container queries): narrow banners stack, wide ones
 * put the actions at the end.
 */
export interface EuiBannerSignature {
  Element: HTMLDivElement;
  Args: {
    /** Heading shown at the top (required). */
    title: string;
    /** Element of the title: `'h2'`–`'h6'`. Defaults to `'h2'`. */
    headingElement?: EuiBannerHeadingElement;
    /** Supporting text below the title. */
    text?: string;
    /**
     * `'s'` (compact, title and text on one line) or `'m'`. Defaults to
     * `'m'`.
     */
    size?: EuiBannerSize;
    /** Background: `'highlighted'` or `'plain'`. Defaults to `'highlighted'`. */
    color?: EuiBannerColor;
    /**
     * Action buttons: `primary` renders an `EuiButton`, `secondary` an
     * `EuiButtonEmpty` (`{ children, onClick, href, iconType, … }`).
     */
    actionProps?: { primary?: EuiBannerAction; secondary?: EuiBannerAction };
    /**
     * Renders a dismiss (cross) button in the top end corner; called when it
     * is clicked.
     */
    onDismiss?: (event: MouseEvent) => void;
    /** Label, size and `css` of the dismiss button. */
    dismissButtonProps?: EuiBannerDismissButtonProps;
    /**
     * Announces the title, text and content to screen readers when the
     * banner is inserted. Use it only when the banner is feedback to a user
     * action, not on page load. Defaults to `false`.
     */
    announceOnMount?: boolean;
    /** Styles composed last into the banner's class (upstream's `css`). */
    css?: EuiCss;
  };
  Blocks: {
    /**
     * The illustration (upstream's required `media`), shown in a square
     * slot; an `<img>` or `<svg>` fills it.
     */
    media?: [];
    /** Extra content below the text. */
    default?: [];
  };
}

export default class EuiBanner extends Component<EuiBannerSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiBannerStyles);
  }

  get size(): EuiBannerSize {
    return this.args.size ?? 'm';
  }

  get color(): EuiBannerColor {
    return this.args.color ?? 'highlighted';
  }

  get headingElement(): EuiBannerHeadingElement {
    return this.args.headingElement ?? 'h2';
  }

  get headingSize() {
    return this.size === 's' ? ('xxs' as const) : ('xs' as const);
  }

  @cached
  get classes() {
    return euiClass(
      this.context,
      this.styles.euiBanner,
      {
        backgroundColor: euiBackgroundColor(this.context.upstream, this.color)
      },
      this.args.css
    );
  }

  @cached
  get containerClass() {
    return euiClass(
      this.context,
      this.styles.container,
      this.args.onDismiss && this.styles.hasDismiss
    );
  }

  @cached
  get mediaClass() {
    return euiClass(this.context, this.styles.media);
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

  get titleCss(): EuiCss {
    return this.styles.title;
  }

  get textCss(): EuiCss {
    return this.styles.text;
  }

  @cached
  get dismissCss(): EuiCss {
    return [this.styles.dismiss, this.args.dismissButtonProps?.css];
  }

  get dismissLabel(): string {
    return (
      this.args.dismissButtonProps?.['aria-label'] ??
      this.euiI18n.lookupToken(
        'euiBanner.dismissAriaLabel',
        ({ title }) => `Dismiss "${String(title)}" announcement`,
        { title: this.args.title }
      )
    );
  }

  onPrimary = (event: MouseEvent): void => {
    this.args.actionProps?.primary?.onClick?.(event);
  };

  onSecondary = (event: MouseEvent): void => {
    this.args.actionProps?.secondary?.onClick?.(event);
  };

  <template>
    <div
      class="euiBanner {{this.classes}}"
      data-size={{this.size}}
      data-color={{this.color}}
      data-test-subj="euiBanner"
      ...attributes
    >
      <div class="euiBanner__container {{this.containerClass}}">
        {{#if (has-block "media")}}
          <div
            class="euiBanner__media {{this.mediaClass}}"
            data-test-subj="euiBanner-media"
          >{{yield to="media"}}</div>
        {{/if}}
        <div class="euiBanner__body {{this.bodyClass}}">
          <div class="euiBanner__content {{this.contentClass}}">
            <EuiTitle
              @size={{this.headingSize}}
              @tagName={{this.headingElement}}
              @css={{this.titleCss}}
              data-test-subj="euiBanner-title"
            >{{@title}}</EuiTitle>
            {{#if @onDismiss}}
              <EuiButtonIcon
                @iconType="cross"
                @color="text"
                @size={{@dismissButtonProps.size}}
                @iconSize={{@dismissButtonProps.iconSize}}
                @isDisabled={{@dismissButtonProps.isDisabled}}
                @css={{this.dismissCss}}
                aria-label={{this.dismissLabel}}
                data-test-subj={{if
                  @dismissButtonProps.data-test-subj
                  @dismissButtonProps.data-test-subj
                  "euiBanner-dismiss"
                }}
                {{on "click" @onDismiss}}
              />
            {{/if}}
            {{#if @text}}
              <EuiText
                @css={{this.textCss}}
                @size="s"
                @color="subdued"
                data-test-subj="euiBanner-text"
              >{{@text}}</EuiText>
            {{/if}}
            {{yield}}
          </div>
          {{#if (or @actionProps.primary @actionProps.secondary)}}
            <div
              class="euiBanner__actions {{this.actionsClass}}"
              data-test-subj="euiBanner-actions"
            >
              {{#if @actionProps.primary}}
                <EuiButton
                  @color="primary"
                  @size="s"
                  @href={{@actionProps.primary.href}}
                  @target={{@actionProps.primary.target}}
                  @iconType={{@actionProps.primary.iconType}}
                  @isDisabled={{@actionProps.primary.isDisabled}}
                  @isLoading={{@actionProps.primary.isLoading}}
                  data-test-subj={{if
                    @actionProps.primary.data-test-subj
                    @actionProps.primary.data-test-subj
                    "euiBanner-primaryAction"
                  }}
                  {{on "click" this.onPrimary}}
                >{{@actionProps.primary.children}}</EuiButton>
              {{/if}}
              {{#if @actionProps.secondary}}
                <EuiButtonEmpty
                  @color="primary"
                  @size="s"
                  @href={{@actionProps.secondary.href}}
                  @target={{@actionProps.secondary.target}}
                  @iconType={{@actionProps.secondary.iconType}}
                  @isDisabled={{@actionProps.secondary.isDisabled}}
                  @isLoading={{@actionProps.secondary.isLoading}}
                  data-test-subj={{if
                    @actionProps.secondary.data-test-subj
                    @actionProps.secondary.data-test-subj
                    "euiBanner-secondaryAction"
                  }}
                  {{on "click" this.onSecondary}}
                >{{@actionProps.secondary.children}}</EuiButtonEmpty>
              {{/if}}
            </div>
          {{/if}}
        </div>
      </div>
      {{#if @announceOnMount}}
        {{! One line: the separators follow the words directly, as upstream. }}
        <EuiLiveAnnouncer>{{@title}}{{#if (and @title @text)}},&nbsp;{{/if}}{{@text}}{{#if
              (and (or @title @text) (has-block))
            }},&nbsp;{{/if}}{{yield}}</EuiLiveAnnouncer>
      {{/if}}
    </div>
  </template>
}
