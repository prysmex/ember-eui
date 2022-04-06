---
order: 4
---

# Remove files programatically

<EuiText>
  <p>
    The current file selection can be cleared programmatically by calling the <EuiCode>removeFiles</EuiCode> method on the <strong>EuiFilePicker ref</strong>.
  </p>
</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiFilePicker
      @ref={{set this 'filePickerRef'}}
      @multiple={{true}}
      @initialPromptText='Select or drag and drop multiple files'
      @onChange={{this.onChange}}
      @display='large'
      aria-label='Use aria labels when no actual label is in use'
    />
  </EuiFlexItem>
  <EuiFlexItem>
    <div>
      <EuiButton
        @color='danger'
        @iconType='trash'
        @disabled={{eq this.files.length 0}}
        {{on 'click' this.filePickerRef.removeFiles}}
      >
        <h3>Remove files</h3>
      </EuiButton>
    </div>
  </EuiFlexItem>
</EuiFlexGroup>

{{#if (gt this.files.length 0)}}
  <EuiSpacer />
  <EuiTitle>FilesAttached:</EuiTitle>
  <EuiSpacer @size='xs' />
  <ul>
    {{#each this.files as |file|}}
      <li>{{file.name}}</li>
    {{/each}}
  </ul>
{{/if}}
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class extends Component {
  @tracked files = [];
  @tracked filePickerRef;

  onChange = (fileList) => {
    this.files = fileList;
  };
}
```
