---
order: 1
---

# Basic file picker

```hbs template
<EuiFilePicker @onChange={{set this 'files'}} />

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
}
```
