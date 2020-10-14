import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/string';
import { action } from '@ember/object';
import { argOrDefaultDecorator as argOrDefault } from 'ember-eui/helpers/arg-or-default';
import { sizeMapping } from 'ember-eui/utils/css-mappings/eui-image';

type EuiImageSize = keyof typeof sizeMapping;

type ImageSize = EuiImageSize | number;

type ImageArgs = {
  /*
    Determines the size of the image itself, can be a number or a string
    Default: 'm'
  */
  size: ImageSize;
};

export default class EmberEuiImage extends GlimmerComponent<ImageArgs> {
  @tracked isFullscreen = false;
  @tracked sizeStyle: unknown = '';
  @argOrDefault('original') size!: ImageArgs['size'];

  get sizeClass(): string | undefined {
    if (typeof this.size === 'number') {
      this.sizeStyle = htmlSafe(
        `max-height:${this.args.size}px; max-width:${this.args.size}px; width:auto;`
      );
    }
    return sizeMapping[this.size as EuiImageSize];
  }

  @action
  toggleFullscreen() {
    this.isFullscreen = !this.isFullscreen;
  }
}
