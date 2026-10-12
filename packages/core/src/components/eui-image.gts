import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { focusTrap } from 'ember-focus-trap';
import { or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiImageButtonIconStyles,
  euiImageButtonStyles,
  euiImageCaptionStyles,
  euiImageFullscreenWrapperStyles,
  euiImageStyles,
  euiImageWrapperStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
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

  /** A visible caption, also the figure's accessible name. */
  caption?: string;
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
  Element: HTMLElement;
  Args: ImageArgs;
  Blocks: {
    /** Unused. */
    default: [];
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
      this.isFullWidth ? styles.fullWidth : undefined
    )}`;
  }

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

  get openIconClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageButtonIconStyles);
    return `euiImageButton__icon ${euiClass(
      this.context,
      styles.euiImageButton__icon,
      styles.openFullScreen
    )}`;
  }

  get closeIconClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageButtonIconStyles);
    return `euiImageButton__icon ${euiClass(
      this.context,
      styles.euiImageButton__icon,
      styles.closeFullScreen
    )}`;
  }

  get captionClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageCaptionStyles);
    return `euiImageCaption ${euiClass(this.context, styles.euiImageCaption)}`;
  }

  get overlayCaptionClasses() {
    const styles = useEuiBorealisStyles(this.context, euiImageCaptionStyles);
    return `euiImageCaption ${euiClass(
      this.context,
      styles.euiImageCaption,
      styles.isOnOverlayMask
    )}`;
  }

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
    <figure
      class={{this.wrapperClasses}}
      aria-label={{@caption}}
      ...attributes
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
          />
          <span class={{this.openIconClasses}}>
            <span class={{this.screenReaderClasses}}>
              {{~if @alt " — "}}{{this.openInstructions~}}
            </span>
            <EuiIcon @type="fullScreen" @color={{this.iconColor}} />
          </span>
        </button>
      {{else}}
        <img class={{this.imageClasses}} src={{or @src @url}} alt={{@alt}} />
      {{/if}}
      {{#if @caption}}
        <figcaption class={{this.captionClasses}}>{{@caption}}</figcaption>
      {{/if}}
    </figure>

    {{#if this.isFullScreen}}
      <EuiOverlayMask
        data-test-subj="fullScreenOverlayMask"
        @onClick={{this.closeFullScreen}}
      >
        <figure
          class={{this.fullScreenWrapperClasses}}
          aria-label={{@caption}}
          {{focusTrap
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
            />
          </button>
          {{#if @caption}}
            <figcaption class={{this.overlayCaptionClasses}}>
              {{@caption}}
            </figcaption>
          {{/if}}
        </figure>
        <EuiIcon
          class={{this.closeIconClasses}}
          @type="fullScreenExit"
          @color="ghost"
        />
      </EuiOverlayMask>
    {{/if}}
  </template>
}
