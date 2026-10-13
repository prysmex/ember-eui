---
order: 1
---

# Base editor

<EuiText>

Use the base editor to produce technical content in markdown which can contain text, code, and images. Besides this default markdown content, the base editor comes with several default plugins that let you add emojis, to-do lists, and tooltips, which can be configured or removed as needed.

Consider applying the <EuiCode>@readOnly</EuiCode> argument to restrict editing during asynchronous submit events, like when submitting a comment. This will ensure users understand that the content cannot be changed while the comment is being submitted.

</EuiText>

<EuiSpacer />

```hbs template
<EuiMarkdownEditor
  @ariaLabel='EUI markdown editor demo'
  @placeholder='Your markdown here...'
  @value={{this.value}}
  @onChange={{this.setValue}}
  @height={{400}}
  @onParse={{this.onParse}}
  @errors={{this.messages}}
  @dropHandlers={{this.dropHandlers}}
  @readOnly={{this.isReadOnly}}
  @initialViewMode='viewing'
/>
<EuiSpacer @size='s' />
<EuiFlexGroup @alignItems='center'>
  <EuiFlexItem @grow={{true}}>
    <EuiSwitch
      @label='Read-only'
      @checked={{this.isReadOnly}}
      @onChange={{this.toggleReadOnly}}
    />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton
      @size='s'
      @iconType={{if this.isAstShowing 'eyeClosed' 'eye'}}
      @fill={{this.isAstShowing}}
      {{on 'click' this.toggleAst}}
    >
      {{if this.isAstShowing 'Hide editor AST' 'Show editor AST'}}
    </EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size='s' />
{{#if this.isAstShowing}}
  <EuiCodeBlock @language='json'>{{this.ast}}</EuiCodeBlock>
{{/if}}
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class BaseEditor extends Component {
  @tracked value = `## Hello world!

Basic "GitHub flavored" markdown will work as you'd expect.

The editor also ships with some built in plugins. For example it can handle checkboxes. Notice how they toggle state even in the preview mode.

- [ ] Checkboxes
- [x] Can be filled
- [ ] Or empty

It can also handle emojis! :smile:
And it can render !{tooltip[tooltips like this](Look! I'm a very helpful tooltip content!)}
`;
  @tracked messages = [];
  @tracked ast = '';
  @tracked isAstShowing = false;
  @tracked isReadOnly = false;

  dropHandlers = [
    {
      supportedFiles: ['.jpg', '.jpeg'],
      accepts: (itemType) => itemType === 'image/jpeg',
      getFormattingForItem: (item) => {
        // fake an upload
        return new Promise((resolve) => {
          setTimeout(() => {
            const url = URL.createObjectURL(item);
            resolve({
              text: `![${item.name}](${url})`,
              config: { block: true },
            });
          }, 1000);
        });
      },
    },
  ];

  @action setValue(value) {
    this.value = value;
  }

  @action onParse(err, { messages, ast }) {
    this.messages = err ? [err] : messages;
    this.ast = JSON.stringify(ast, null, 2);
  }

  @action toggleReadOnly(event) {
    this.isReadOnly = event.target.checked;
  }

  @action toggleAst() {
    this.isAstShowing = !this.isAstShowing;
  }
}
```
