---
order: 1
---

# Demo

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow @label="Some Input" @helpText="here's some help text" @id={{inputId}}>
      <EuiFilePicker @onChange={{set this "files"}} />
    </EuiFormRow>
  {{/let}}
  {{#each this.files as |file|}}
    {{file.name}}
  {{/each}}
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked files = [];
}
```
