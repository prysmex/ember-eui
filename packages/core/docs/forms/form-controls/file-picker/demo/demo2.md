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
  <EuiText @size="s">
    <p><strong>Files attached:</strong></p>
    <ul>
      {{#each this.files as |file|}}
        <li>{{file.name}} ({{file.size}} bytes)</li>
      {{/each}}
    </ul>
  </EuiText>
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
