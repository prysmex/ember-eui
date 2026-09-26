---
order: 1
---

# Basic file picker

```hbs template
<EuiFilePicker @onChange={{set this 'files'}} />

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
}
```
