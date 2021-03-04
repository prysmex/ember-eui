---
order: 1
---

# Demo

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow @label="Some Input" @helpText="here's some help text" @id={{inputId}}>
      <EuiFieldPassword
        @value={{this.password}}
        @id={{inputId}}
        {{on "input" (pick "target.value" (set this.password))}}
      />
    </EuiFormRow>
  {{/let}}
  <EuiHorizontalRule />
  <EuiTitle>
    With Errors
  </EuiTitle>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow
      @label="Some Input"
      @id={{inputId}}
      @isInvalid={{true}}
      @error={{array "error one" "error two"}}
      @helpText="here's some help text"
    >
      <EuiFieldPassword
        @value={{this.password2}}
        @id={{inputId}}
        {{on "input" (pick "target.value" (set this.password2))}}
      />
    </EuiFormRow>
  {{/let}}
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked password = '';
  @tracked password2 = '';
}
```
