import DocfyDemoSnippet from '@docfy/ember/components/docfy-demo/snippet';

export default class extends DocfyDemoSnippet {
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
