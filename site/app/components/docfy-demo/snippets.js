import { action } from '@ember/object';
import { schedule } from '@ember/runloop';

import DocfyDemoSnippets from '@docfy/ember/components/docfy-demo/snippets';

export default class extends DocfyDemoSnippets {
  @action
  registerSnippet(snippet) {
    schedule('render', this, () => {
      this.snippets = [...this.snippets, snippet];
    });
  }
}
