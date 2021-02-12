---
order: 1
---

# Demo

```hbs template
<EuiForm>
  <EuiFormRow @label="Some Select" @helpText="here's some help text">
    <EuiSelect
      @value={{this.select1}}
      @hasNoInitialSelection={{true}}
      @options={{array (hash value="1" text="hello") (hash value="2" text="goodbye")}}
      {{on "change" (pick "target.value" (set this.select1))}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}}>
          Here's a label
        </EuiFormLabel>
      </:prepend>
    </EuiSelect>
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
    <EuiSelect
      @value={{this.select2}}
      @hasNoInitialSelection={{true}}
      @options={{array (hash value="1" text="hello") (hash value="2" text="goodbye")}}
      {{on "change" (pick "target.value" (set this.select2))}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}}>
          Here's a label
        </EuiFormLabel>
      </:prepend>
    </EuiSelect>
  </EuiFormRow>
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked select1 = '';
  @tracked select2 = '';
}
```
