import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/string';
import { action } from '@ember/object';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { sizeMapping } from '../../utils/css-mappings/eui-image';

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
};

export default class EuiImage extends GlimmerComponent<ImageArgs> {
  @tracked isFullscreen = false;
  @argOrDefault('original') size!: ImageArgs['size'];

  get sizeClass(): string | undefined {
    return sizeMapping[this.size as EuiImageSize];
  }

  get sizeStyle(): ReturnType<typeof htmlSafe> | string {
    const size = this.args.size;
    if ((typeof size === 'string' || typeof size === 'number') && !this.sizeClass) {
      return htmlSafe(`max-height:${this.args.size}px; max-width:${this.args.size}px; width:auto;`);
    }
    return '';
  }

  @action
  toggleFullscreen(): void {
    this.isFullscreen = !this.isFullscreen;
  }
}
