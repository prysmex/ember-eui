---
order: 10
---

# A toolbar plugin (Ember EUI extra)

<EuiText>

A UI plugin adds a toolbar button. With `formatting`, clicking it wraps
the selection (`prefix` / `suffix`) or prefixes each selected line
(`multiline`); this one turns the selection into a quote. Its
`helpText` shows in the editor's help popover.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiMarkdownEditor } from '@ember-eui/core/components';
import { getDefaultEuiMarkdownUiPlugins } from '@ember-eui/core/utils/markdown/plugins/markdown-default-plugins/index';

const quotePlugin = {
  name: 'quote',
  button: { label: 'Quote', iconType: 'quote' },
  formatting: { prefix: '> ', multiline: true, surroundWithNewlines: true },
  helpText: 'Select text and press the quote button to quote it.',
};

export default class ToolbarPluginDemo extends Component {
  // `@uiPlugins` replaces the default plugins (the tooltip button): add to them.
  uiPlugins = [...getDefaultEuiMarkdownUiPlugins(), quotePlugin];

  @tracked value = 'Select this sentence and press the quote button.';

  @action
  update(value) {
    this.value = value;
  }

  <template>
    <EuiMarkdownEditor
      @value={{this.value}}
      @onChange={{this.update}}
      @uiPlugins={{this.uiPlugins}}
      @height={{180}}
      @ariaLabel="Editor with a quote button"
    />
  </template>
}
```

