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
    <:field as |fieldApi|>
      <EuiFieldText
        value={{this.num2}}
        @prepend={{array
          "Salute"
          (component
            "with-attributes"
            componentName=(component "eui-button-icon" iconType="faceSad")
            events=(array (hash event="click" handler=this.salute))
          )
        }}
        {{html-events fieldApi.events}}
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

  @action
  change(n) {
    this.num += n;
  }
}
```
