---
order: 1
---

# Demo

> Because of Ember limitations of metaprogramming between child and parent html events and attributes, we need to use html-events modifer in order to pass eui-form-row events to the wrapped fields, to accomplish stuff like onFocus... highlight the label.

```hbs template
<EuiForm>
  <EuiFormRow @label="Some Input" @helpText="here's some help text">
    <EuiFieldText value={{this.num}} {{on "input" (pick "target.value" (set this.num))}}>
      <:prepend as |classes|>
        <EuiButtonIcon
          class={{classes}}
          @size="xs"
          @iconType="faceHappy"
          {{on "click" this.salute}}
        />
      </:prepend>
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>
          Salute
        </EuiFormLabel>
        <EuiButtonIcon
          class={{classes}}
          @size="xs"
          @iconType="faceHappy"
          {{on "click" this.salute}}
        />
      </:append>
    </EuiFieldText>
  </EuiFormRow>
  <EuiHorizontalRule />
  <EuiTitle>
    With Errors
  </EuiTitle>
  <EuiFormRow @label="Some Input" @helpText="here's some help text" @error={{array "error"}} @isInvalid={{true}}>
    <EuiFieldText value={{this.num2}} {{on "input" (pick "target.value" (set this.num2))}} />
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
    alert('hello');
  }
}
```
