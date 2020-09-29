import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/string';
import { action } from '@ember/object';
import { sizeMapping } from '../../utils/css-mappings/eui-image';

export default class EmberEuiImage extends GlimmerComponent {

  // TODO: allowFullscreen functionality

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