import DocfyDemoSnippet from 'prysmex-docfy-ember/components/docfy-demo/snippet';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';
import ThemeManager from 'site/services/theme-manager';

export default class extends DocfyDemoSnippet {
  @service declare themeManager: ThemeManager;

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
