import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/string';
import { action } from '@ember/object';

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
      switch (this.size) {
        case 's':
          return 'euiImage--small '
        case 'm':
          return 'euiImage--medium '
        case 'l':
          return 'euiImage--large '
        case 'xl':
          return 'euiImage--xlarge '
        case 'fullWidth':
          return 'euiImage--fullWidth '
        case 'original':
          break;
        default:
          return '';
      }
    }
  }

  @action
  toggleFullscreen() {
    console.log('clicked!')
    this.isFullscreen = !this.isFullscreen;
  }

}