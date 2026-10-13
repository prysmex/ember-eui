---
order: 11
---

# Customization

<EuiText>

Customize the editor toolbar by passing <EuiCode>@toolbarProps</EuiCode>. <EuiCode>right</EuiCode> replaces the default preview/editor switch on the right of the toolbar with your content (text, or a component: upstream passes a React node), and <EuiCode>className</EuiCode> adds a class to the toolbar. Without <EuiCode>right</EuiCode> the default switch stays.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiMarkdownEditor } from '@ember-eui/core/components';

const Validate = <template>
  <EuiButton @iconType='check' @size='s'>Validate</EuiButton>
</template>;

export default class ToolbarCustomization extends Component {
  toolbarProps = { right: Validate };

  @tracked value = `## Hello world!

Basic "GitHub flavored" markdown will work as you'd expect.

It can also handle emojis! :smile:
`;

  @action setValue(value) {
    this.value = value;
  }

  <template>
    <EuiMarkdownEditor
      @ariaLabel='Editor with a custom toolbar'
      @value={{this.value}}
      @onChange={{this.setValue}}
      @height={{300}}
      @toolbarProps={{this.toolbarProps}}
    />
  </template>
}
```
