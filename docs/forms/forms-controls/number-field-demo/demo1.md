---
order: 1
---

# Demo

```hbs template
<EuiForm>
  <EuiFormRow
    @label="Some Input"
    @helpText="here's some help text">
    <EuiFieldNumber
      value={{this.num}}
      {{on "input" (pick "target.value" (set this.num))}}
    />
  </EuiFormRow>

  <EuiFormRow
    @label="Some Input"
    @helpText="here's some help text">
    <EuiFieldNumber
      value={{this.num}}
      {{on "input" (pick "target.value" (set this.num))}}
    >
      <:prepend as |classes|>
        <EuiButtonIcon @iconType="faceHappy" class={{classes}} {{on "click" this.salute}}/>
      </:prepend>
    </EuiFieldNumber>
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
    <EuiFieldNumber
      value={{this.num2}}
      {{on "input" (pick "target.value" (set this.num2))}}
    />
  </EuiFormRow>
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked num = 1;
  @tracked num2 = 1;

  salute() {
    alert('hey');
  }
}
```
