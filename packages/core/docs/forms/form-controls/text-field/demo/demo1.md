---
order: 1
---

<EuiTitle>
  Simple text field
</EuiTitle>

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow @label='Some Input' @id={{inputId}}>
      <EuiFieldText
        @value={{this.num}}
        @id={{inputId}}
        {{on 'input' (pick 'target.value' (set this 'num'))}}
      />
    </EuiFormRow>
  {{/let}}
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked num = 1;

  salute() {
    alert('hello');
  }
}
```
