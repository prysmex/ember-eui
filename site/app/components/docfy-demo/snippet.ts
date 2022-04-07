import DocfyDemoSnippet from '@docfy/ember/components/docfy-demo/snippet';
import { tracked } from '@glimmer/tracking';
export default class extends DocfyDemoSnippet {
  @tracked isSingleSelected = false;
  get language() {
    switch (this.args.name) {
      case 'template':
        return 'hbs';
      case 'component':
        return 'js';
      default:
        return undefined;
    }
  }
}
