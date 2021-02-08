---
order: 1
---

# Demo

> Because of Ember limitations of metaprogramming between child and parent html events and attributes, we need to use html-events modifer in order to pass eui-form-row events to the wrapped fields, to accomplish stuff like onFocus... highlight the label.

```hbs template
<EuiForm>
  <EuiFormRow
    @label="Some Input"
    @helpText="here's some help text"
    as |fieldApi|>
    <EuiFieldNumber
      value={{this.num}}
      @prepend={{array
        "Salute"
        (component
          "with-attributes"
          componentName=(component "eui-button-icon" iconType="faceHappy")
          events=(array (hash event="click" handler=this.salute))
        )
      }}
      {{html-events fieldApi.events}}
      {{on "input" (pick "target.value" (set this.num))}}
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
    as |fieldApi|
  >
    <EuiFieldNumber
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

  @action
  change(n) {
    this.num += n;
  }
}
```
