import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { focusTrap } from 'ember-focus-trap';
import spreadAttributes from '../-private/eui-spread-attributes.ts';
import { focusTrapFactory } from '../-private/focus-trap-registry.ts';
import style from 'ember-style-modifier/modifiers/style';
import { or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiImageButtonIconStyles,
  euiImageButtonStyles,
  euiImageCaptionStyles,
  euiImageFullscreenWrapperStyles,
  euiImageStyles,
  euiImageWrapperStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';
import EuiOverlayMask from './eui-overlay-mask.gts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n.ts';
import type { CSSObject } from '@emotion/css/create-instance';

/** Upstream named sizes. */
export const IMAGE_SIZES = ['s', 'm', 'l', 'xl', 'original', 'fullWidth'] as const;

export type EuiImageSize = (typeof IMAGE_SIZES)[number];

function isNamedSize(size: unknown): size is EuiImageSize {
  return (IMAGE_SIZES as readonly unknown[]).includes(size);
}

// React's global reset zeroes figure margins and strips button chrome.
/** `wrapperProps` keys handled by the template, not spread as attributes. */
const WRAPPER_PROPS = ['id', 'role', 'aria-label', 'data-test-subj', 'style'];

const figureReset: CSSObject = { boxSizing: 'border-box', margin: 0 };
const buttonReset: CSSObject = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none',
  background: 'none',
  color: 'inherit',
  font: 'inherit'
};

/**
 * Upstream's `wrapperProps` for the `<figure>`. The keys below are
 * handled; any other key with a string, number or boolean value is set
 * as an attribute of the figure (upstream spreads `wrapperProps`).
 */
export interface EuiImageWrapperProps {
  /** Added to the figure's classes. */
  className?: string;
  /** Styles composed last into the figure's class (upstream's `css`). */
  css?: EuiCss;
  /** Inline styles of the figure, as an object. */
  style?: Record<string, string | undefined>;
  id?: string;
  role?: string;
  /** Replaces the figure's accessible name (the caption's text). */
  'aria-label'?: string;
  'data-test-subj'?: string;
  [attribute: string]: unknown;
}

type ImageArgs = {
  /**
   * Describes the image for screen reader users (required). Pass an empty
   * string when the image is decorative or described by nearby text.
   */
  alt: string;

  /**
   * `'s'` (100px), `'m'` (200px), `'l'` (360px), `'xl'` (600px),
   * `'fullWidth'`, `'original'`, or a custom maximum size: a number (px)
   * or a CSS length such as `'50%'`. Defaults to `'original'`.
   */
  size?: EuiImageSize | number | string;

  /**
   * Color of the icon over a full screen image: `'light'` (default) or
   * `'dark'` (for images with a white background).
   */
  fullScreenIconColor?: 'light' | 'dark';

  /** URL of the image. */
  url?: string;

  /**
   * A visible caption, also the figure's accessible name. For rich content
   * use the `<:caption>` block instead.
   */
  caption?: string;

  /** The `width` attribute of the image, e.g. for SVGs without a size. */
  width?: number | string;

  /** Props of the wrapping `<figure>`. */
  wrapperProps?: EuiImageWrapperProps;
  /** Adds a slight shadow to the image. Defaults to `false`, as upstream. */
  hasShadow?: boolean;
  /** Makes the image clickable to show a larger version over the page. */
  allowFullScreen?: boolean;

  /** Floats the image `'left'` or `'right'` of the text around it (from the `m` breakpoint). */
  float?: 'left' | 'right' | 'none';

  /** Space around the image: `'none'`, `'s'`, `'m'`, `'l'` or `'xl'`. */
  margin?: 'none' | 's' | 'm' | 'l' | 'xl';

  /** Accessible label of the full screen button (`@allowFullScreen`), replacing the instructions. */
  ariaLabel?: string;

  /** Called with `true` / `false` when the full screen view opens / closes. */
  onFullScreen?: (isFullScreen: boolean) => void;

  /** Same as `@url`; wins when both are given. */
  src?: string;
};

/** An image with an optional caption, shadow and full screen view. */
export interface EuiImageSignature {
  /**
   * Attributes go on the `<img>` (and on the full screen one), as
   * upstream's rest props; use `@wrapperProps` for the `<figure>`.
   */
  Element: HTMLImageElement;
  Args: ImageArgs;
  Blocks: {
    /** Unused. */
    default: [];
    /**
     * Rich caption (upstream's node `caption`), instead of `@caption`. The
     * figure's accessible name is the caption's text.
     */
    caption: [];
  };
}

export default class EuiImage extends Component<EuiImageSignature> {
  @service declare euiI18n: EuiI18n;
  @tracked isFullScreen = false;

  get context() {
    return getEuiThemeContext(this);
  }

  get size() {
    return this.args.size ?? 'original';
  }

  get isFullWidth() {
    return this.size === 'fullWidth';
  }

  get iconColor() {
    return this.args.fullScreenIconColor === 'dark' ? 'default' : 'ghost';
  }

  get openInstructions() {
    return this.euiI18n.lookupToken(
      'euiImageButton.openFullScreen',
      'Click to open this image in fullscreen mode'
    );
  }

  get closeInstructions() {
    return this.euiI18n.lookupToken(
      'euiImageButton.closeFullScreen',
      'Press Escape or click to close image fullscreen mode'
    );
  }

  get screenReaderClasses() {
    return euiScreenReaderOnlyClass(this.context);
  }

  @cached
  get wrapperClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageWrapperStyles);
    const { float, margin } = this.args;
    return `euiImageWrapper ${euiClass(
      this.context,
      figureReset,
      styles.euiImageWrapper,
      float && float !== 'none' ? styles[float] : undefined,
      margin && margin !== 'none' ? styles[margin] : undefined,
      this.args.allowFullScreen ? styles.allowFullScreen : undefined,
      this.isFullWidth ? styles.fullWidth : undefined,
      this.args.wrapperProps?.css
    )}${
      this.args.wrapperProps?.className
        ? ` ${this.args.wrapperProps.className}`
        : ''
    }`;
  }

  @cached
  get imageClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageStyles);
    const size = this.size;
    let custom: CSSObject | undefined;
    if (!isNamedSize(size)) {
      const value =
        typeof size === 'number' || /^\d+(\.\d+)?$/.test(size)
          ? `${size}px`
          : size;
      custom = { maxWidth: value, maxHeight: value };
    }
    return `euiImage ${euiClass(
      this.context,
      styles.euiImage,
      isNamedSize(size) ? styles[size] : styles.customSize,
      this.args.hasShadow ? styles.hasShadow : undefined,
      custom
    )}`;
  }

  @cached
  get fullScreenImageClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageStyles);
    return `euiImage ${euiClass(this.context, styles.euiImage, styles.isFullScreen)}`;
  }

  buttonClasses(isFullScreen: boolean) {
    const styles = useEuiBorealisStyles(this.context, euiImageButtonStyles);
    return `euiImageButton ${euiClass(
      this.context,
      buttonReset,
      styles.euiImageButton,
      this.args.hasShadow ? styles.hasShadowHover : styles.shadowHover,
      !isFullScreen && this.isFullWidth ? styles.fullWidth : undefined
    )}`;
  }

  get openButtonClasses() {
    return this.buttonClasses(false);
  }

  get closeButtonClasses() {
    return this.buttonClasses(true);
  }

  @cached
  get openIconClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageButtonIconStyles);
    return `euiImageButton__icon ${euiClass(
      this.context,
      styles.euiImageButton__icon,
      styles.openFullScreen
    )}`;
  }

  @cached
  get closeIconCss(): EuiCss {
    const styles = useEuiBorealisStyles(this.context, euiImageButtonIconStyles);
    return [styles.euiImageButton__icon, styles.closeFullScreen];
  }

  @cached
  get captionClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageCaptionStyles);
    return `euiImageCaption ${euiClass(this.context, styles.euiImageCaption)}`;
  }

  @cached
  get overlayCaptionClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageCaptionStyles);
    return `euiImageCaption ${euiClass(
      this.context,
      styles.euiImageCaption,
      styles.isOnOverlayMask
    )}`;
  }

  @cached
  get fullScreenWrapperClasses() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiImageFullscreenWrapperStyles
    );
    return `euiImageFullScreenWrapper ${euiClass(
      this.context,
      figureReset,
      styles.euiImageFullscreenWrapper,
      this.isFullWidth ? styles.fullWidth : undefined
    )}`;
  }

  openFullScreen = (e: Event) => {
    e.preventDefault();
    e.stopPropagation();
    this.isFullScreen = true;
    this.args.onFullScreen?.(true);
  };

  closeFullScreen = (e?: Event) => {
    e?.preventDefault();
    e?.stopPropagation();
    if (!this.isFullScreen) return;
    this.isFullScreen = false;
    this.args.onFullScreen?.(false);
  };

  onKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') this.closeFullScreen(e);
  };

  <template>
    <EuiInnerText as |captionRef captionText|>
    <figure
      class={{this.wrapperClasses}}
      id={{@wrapperProps.id}}
      role={{@wrapperProps.role}}
      data-test-subj={{get @wrapperProps "data-test-subj"}}
      aria-label={{or (get @wrapperProps "aria-label") @caption captionText undefined}}
      {{style @wrapperProps.style}}
      {{spreadAttributes @wrapperProps WRAPPER_PROPS}}
    >
      {{#if @allowFullScreen}}
        <button
          class={{this.openButtonClasses}}
          type="button"
          aria-label={{@ariaLabel}}
          data-test-subj="activateFullScreenButton"
          {{on "click" this.openFullScreen}}
        >
          <img
            class={{this.imageClasses}}
            src={{or @src @url}}
            alt={{@alt}}
            width={{@width}}
            ...attributes
          />
          <span class={{this.openIconClasses}}>
            <span class={{this.screenReaderClasses}}>
              {{~if @alt " — "}}{{this.openInstructions~}}
            </span>
            <EuiIcon @type="fullScreen" @color={{this.iconColor}} />
          </span>
        </button>
      {{else}}
        <img
          class={{this.imageClasses}}
          src={{or @src @url}}
          alt={{@alt}}
          width={{@width}}
          ...attributes
        />
      {{/if}}
      {{#if (or @caption (has-block "caption"))}}
        <figcaption class={{this.captionClasses}} {{didInsert captionRef}}>
          {{#if (has-block "caption")}}
            {{yield to="caption"}}
          {{else}}
            {{@caption}}
          {{/if}}
        </figcaption>
      {{/if}}
    </figure>
    </EuiInnerText>

    {{#if this.isFullScreen}}
      <EuiOverlayMask
        data-test-subj="fullScreenOverlayMask"
        @onClick={{this.closeFullScreen}}
      >
        <EuiInnerText as |overlayCaptionRef overlayCaptionText|>
        <figure
          class={{this.fullScreenWrapperClasses}}
          aria-label={{or @caption overlayCaptionText undefined}}
          {{focusTrap
          _createFocusTrap=focusTrapFactory
            focusTrapOptions=(hash
              clickOutsideDeactivates=true escapeDeactivates=false
            )
          }}
        >
          <button
            class={{this.closeButtonClasses}}
            type="button"
            data-test-subj="deactivateFullScreenButton"
            {{on "click" this.closeFullScreen}}
            {{on "keydown" this.onKeyDown}}
          >
            <span class={{this.screenReaderClasses}}>
              {{~this.closeInstructions}}{{if @alt " — "~}}
            </span>
            <img
              class={{this.fullScreenImageClasses}}
              src={{or @src @url}}
              alt={{@alt}}
              width={{@width}}
              ...attributes
            />
          </button>
          {{#if (or @caption (has-block "caption"))}}
            <figcaption
              class={{this.overlayCaptionClasses}}
              {{didInsert overlayCaptionRef}}
            >
              {{#if (has-block "caption")}}
                {{yield to="caption"}}
              {{else}}
                {{@caption}}
              {{/if}}
            </figcaption>
          {{/if}}
        </figure>
        </EuiInnerText>
        <EuiIcon
          class="euiImageButton__icon"
          @css={{this.closeIconCss}}
          @type="fullScreenExit"
          @color="ghost"
        />
      </EuiOverlayMask>
    {{/if}}
  </template>
}
