---
order: 3
---

# Large file picker

<EuiText>
  <p>
    By default <strong>EuiFilePicker</strong> is rendered with the same height as the other controls, but you can pass <EuiCode>@display="large"</EuiCode> for a taller size.
  </p>
</EuiText>

```hbs template
<EuiFilePicker
  @initialPromptText='Select or drag and drop multiple files'
  @onChange={{this.onChange}}
  @multiple={{true}}
  @display='large'
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
