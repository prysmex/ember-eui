---
order: 4
---

<EuiTitle>
  You can use named blocks for further row customization
</EuiTitle>

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow @error={{array 'error 1'}} @isInvalid={{true}} @id={{inputId}}>
      <:label>
        <EuiAvatar @name='row' />
        This is the
        <strong>:label</strong>
        block
      </:label>
      <:field>
        <EuiFieldText
          @value={{this.num}}
          @id={{inputId}}
          {{on 'input' (pick 'target.value' (set this 'num'))}}
        />
      </:field>
      <:errors as |error|>
        {{error}}
      </:errors>
      <:helpText>
        You can also use the
        <strong>:helpText</strong>
        block
      </:helpText>
    </EuiFormRow>
  {{/let}}
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class extends Component {
  @tracked num = 1;
}
```
