---
order: 2
---

<EuiTitle>
  With Errors
</EuiTitle>

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow
      @label='Some Input'
      @helpText="here's some help text"
      @error={{array 'error'}}
      @isInvalid={{true}}
      @id={{inputId}}
    >
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

export default class extends Component {
  @tracked num = 1;

  salute() {
    alert('hello');
  }
}
```
