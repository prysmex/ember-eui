---
order: 2
---

# Allow multiple files

<EuiText>
  <p>
    Pass <EuiCode>@multiple={{true}}</EuiCode> or the HTML attribute <strong>multiple</strong> to allow picking multiple files.
  </p>
</EuiText>

```hbs template
<EuiFilePicker
  @initialPromptText='Select or drag and drop multiple files'
  @onChange={{this.onChange}}
  multiple
  aria-label='Use aria labels when no actual label is in use'
/>

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

  onChange = (fileList) => {
    this.files = fileList;
  };
}
```
