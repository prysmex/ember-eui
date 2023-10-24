import DocfyDemoSnippets, {
  SnippetRegisterArgs
} from '@docfy/ember/components/docfy-demo/snippets';
import { schedule } from '@ember/runloop';
import { action } from '@ember/object';

export default class extends DocfyDemoSnippets {
  @action
  registerSnippet(snippet: SnippetRegisterArgs): void {
    schedule('render', this, () => {
      this.snippets = [...this.snippets, snippet];
    });
  }
}
