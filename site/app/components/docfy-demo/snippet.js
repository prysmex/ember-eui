import DocfyDemoSnippet from '@docfy/ember/components/docfy-demo/snippet';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';

export default class extends DocfyDemoSnippet {
  @service themeManager;

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
