import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';

export default class EmberEuiImage extends GlimmerComponent {

  url = '';
  alt = '';
  size = '';
  @tracked hasShadow = this.args.hasShadow;

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