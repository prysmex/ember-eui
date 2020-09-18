import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';
import { computed } from '@ember/object';
import { htmlSafe } from '@ember/string';

export default class EmberEuiImage extends GlimmerComponent {

  url = '';
  alt = '';
  @tracked hasShadow = this.args.hasShadow;

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

  // caption = '';
  // fullScreenIconColor = '';
  // allowFullScreen = false;
  // className = this.args.className;
  // ariaLabel = '';
  // dataTestSubj = '';

  constructor () {
    super(...arguments);
    if (!this.args.url) {
      assert('You must provide an image url');
    } else {
      this.url = this.args.url;
    }

    if (!this.args.alt) {
      assert('You must provide an image alt text');
    } else {
      this.alt = this.args.alt;
    }
  }


}