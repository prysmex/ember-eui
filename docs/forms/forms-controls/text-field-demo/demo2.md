---
order: 2
---

# Demo 2

```hbs template
<EuiTitle>
  You can use named blocks for further row customization
</EuiTitle>
<EuiForm>
  <EuiFormRow @error={{array "error 1"}} @isInvalid={{true}}>
    <:label>
      <EuiAvatar @name="row" />
      My label
    </:label>
    <:field>
      <EuiFieldText
        value={{this.num2}}
        {{on "input" (pick "target.value" (set this.num2))}}
      />
    </:field>
    <:errors as |error|>
      {{error}}
    </:errors>
    <:helpText>
      Some text
    </:helpText>
  </EuiFormRow>
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo2 extends Component {
  @tracked num = 1;
  @tracked num2 = 1;

  salute() {
    alert('hello');
  }
}
```
