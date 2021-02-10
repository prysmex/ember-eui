---
order: 1
---

# Demo

```hbs template
<EuiForm>
  <EuiFormRow
    @label="Some Input"
    @helpText="here's some help text">
    <EuiFieldPassword
      value={{this.password}}
      {{on "input" (pick "target.value" (set this.password))}}
    />
  </EuiFormRow>

  <EuiHorizontalRule />
  <EuiTitle>
    With Errors
  </EuiTitle>
  <EuiFormRow
    @label="Some Input"
    @isInvalid={{true}}
    @error={{array "error one" "error two"}}
    @helpText="here's some help text"
  >
    <EuiFieldPassword
      value={{this.password2}}
      {{on "input" (pick "target.value" (set this.password2))}}
    />
  </EuiFormRow>
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
