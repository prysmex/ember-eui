---
order: 2
---

# Demo 2

```hbs template
<EuiTitle>
  You can use named blocks for further row customization
</EuiTitle>
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow @error={{array "error 1"}} @isInvalid={{true}} @id={{inputId}}>
      <:label>
        <EuiAvatar @name="row" />
        My label
      </:label>
      <:field>
        <EuiFieldText
          @value={{this.num2}}
          @id={{inputId}}
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
  {{/let}}
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
