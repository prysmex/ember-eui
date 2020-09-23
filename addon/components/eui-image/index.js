import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';
import { computed } from '@ember/object';
import { htmlSafe } from '@ember/string';
import { action } from '@ember/object';

export default class EmberEuiImage extends GlimmerComponent {

  // TODO: allowFullscreen functionality

  size = this.args.size;

  @computed('size')
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
  expandImage() {
    console.log('clicked!')
    let body = document.body;
    body.classList.add('euiBody-hasOverlayMask')
  }

}