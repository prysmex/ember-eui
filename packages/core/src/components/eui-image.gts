import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';

import { focusTrap } from 'ember-focus-trap';
import onKey from 'ember-keyboard/modifiers/on-key';
import { eq, notEq, or } from 'ember-truth-helpers';

import { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import { sizeMapping } from '../utils/css-mappings/eui-image.ts';
import EuiIcon from './eui-icon.gts';
import EuiOverlayMask from './eui-overlay-mask.gts';

type EuiImageSize = keyof typeof sizeMapping;

type ImageSize = EuiImageSize | number;

type FullScreenIconColor = 'light' | 'dark';

type ImageArgs = {
  /**
   * Separate from the caption is a title on the alt tag itself.
   * This one is required for accessibility.
   */
  alt: string;

  /*
    Determines the size of the image itself, can be a number or a string
    Default: 'm'
  */
  size?: ImageSize | number | string;

  /**
   * Changes the color of the icon that floats above the image when it can be clicked to fullscreen.
   * The default value of `light` is fine unless your image has a white background, in which case you should change it to `dark`.
   */
  fullScreenIconColor?: FullScreenIconColor;

  url: string;

  /**
   * Provides the visible caption to the image
   */
  caption?: string;
  /**
   * When set to `true` (default) will apply a slight shadow to the image
   */
  hasShadow?: boolean;
  /**
   * When set to `true` will make the image clickable to a larger version
   */
  allowFullScreen?: boolean;

  /**
   * When set to `true` will make the image clickable to a larger version
   */
  float?: 'left' | 'right' | 'none';

  /**
   * When set to `true` will make the image clickable to a larger version
   */
  margin?: 'none' | 's' | 'm' | 'l' | 'xl';

  /**
   * When set to `true` will make the image clickable to a larger version
   */
  ariaLabel?: string;

  src?: string;
};

export interface EuiImageSignature {
  Element: HTMLElement;
  Args: ImageArgs;
  Blocks: {
    default: [];
  };
}

export default class EuiImage extends Component<ImageArgs> {
  @tracked isFullscreen = false;
  @argOrDefaultDecorator('original') size!: ImageArgs['size'];

  get sizeClass(): string | undefined {
    return sizeMapping[this.size as EuiImageSize];
  }

  get sizeStyle(): ReturnType<typeof htmlSafe> | string {
    const size = this.args.size;

    if (
      (typeof size === 'string' || typeof size === 'number') &&
      !this.sizeClass
    ) {
      return htmlSafe(
        `max-height:${this.args.size}px; max-width:${this.args.size}px; width:auto;`
      );
    }

    return '';
  }

  @action
  toggleFullscreen(e: Event): void {
    e.stopPropagation();
    e.preventDefault();
    this.isFullscreen = !this.isFullscreen;
  }

  get sizeString() {
    if (typeof this.args.size === 'string') {
      return this.args.size;
    }
  }

  <template>
    {{#if @allowFullScreen}}
      <figure
        class={{classNames
          "euiImage--allowFullScreen"
          (unless (eq @hasShadow false) "euiImage--hasShadow")
          float=@float
          margin=@margin
          componentName="EuiImage"
          size=this.sizeString
        }}
        {{!@glint-expect-error}}
        ...attributes
      >

        <button
          class="euiImage__button"
          type="button"
          aria-label={{@ariaLabel}}
          {{on "click" this.toggleFullscreen}}
        >
          <img
            src={{or @src @url}}
            class="euiImage__img"
            style={{this.sizeStyle}}
            alt={{@alt}}
          />
          <EuiIcon
            @iconClasses="euiImage__icon"
            @type="fullScreen"
            @color={{if (notEq @fullScreenIconColor "dark") "ghost"}}
          />
        </button>

        {{#if @caption}}
          <figcaption class="euiImage__caption">
            {{@caption}}
          </figcaption>
        {{/if}}
      </figure>

    {{else}}

      <figure
        class={{classNames
          (unless (eq @hasShadow false) "euiImage--hasShadow")
          float=@float
          margin=@margin
          componentName="EuiImage"
          size=this.sizeString
        }}
        {{!@glint-expect-error}}
        ...attributes
      >

        <img
          src={{or @src @url}}
          class="euiImage__img"
          style={{this.sizeStyle}}
          alt={{@alt}}
        />

        {{#if @caption}}
          <figcaption class="euiImage__caption">
            {{@caption}}
          </figcaption>
        {{/if}}
      </figure>

    {{/if}}

    {{#if this.isFullscreen}}
      <EuiOverlayMask
        @headerZindexLocation="above"
        @onClick={{this.toggleFullscreen}}
      >
        <figure
          class="euiImage euiImage-isFullScreen"
          {{focusTrap focusTrapOptions=(hash clickOutsideDeactivates=true)}}
        >
          <button
            class="euiImage__button"
            type="button"
            {{on "click" this.toggleFullscreen}}
            {{onKey "Escape" this.toggleFullscreen}}
          >
            <img
              class="euiImage-isFullScreen__img"
              src={{or @src @url}}
              alt={{@alt}}
            />
          </button>
          <figcaption class="euiImage__caption">
            {{@caption}}
          </figcaption>
        </figure>
        <EuiIcon
          @iconClasses="euiImage-isFullScreenCloseIcon"
          @type="cross"
          @color={{if (notEq @fullScreenIconColor "dark") "ghost"}}
        />
      </EuiOverlayMask>
    {{/if}}
  </template>
}
