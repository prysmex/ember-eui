import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/string';
import { action } from '@ember/object';
import { sizeMapping } from '../../utils/css-mappings/eui-image';

type ImageArgs = {
  /*
    Determines the size of the image itself, can be a number or a string
    Default: 'm'
  */
  size: number | string;
}

export default class EmberEuiImage extends GlimmerComponent<ImageArgs> {

  @tracked isFullscreen = false;

  get size() {
    return this.args.size || 'original';
  }

  get sizeClass() {
    if (typeof this.size == 'number') {
      this.sizeStyle = htmlSafe(`max-height:${this.args.size}px; max-width:${this.args.size}px; width:auto;`);
    } else {
      return sizeMapping[this.size];
    }
  }

  @action
  toggleFullscreen() {
    this.isFullscreen = !this.isFullscreen;
  }

}