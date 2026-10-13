---
order: 6
---

# Form labels

<EuiText>

The best way to provide an [accessible name](https://www.tpgi.com/what-is-an-accessible-name/) to form elements is to use the `@label` provided by `EuiFormRow`. However, certain types of form controls require extra care to ensure an accessible experience. Below are just a few examples.

Form controls that come with their own label don't need the one provided by `EuiFormRow`. For controls like `EuiSwitch`, `EuiButton`, and `EuiLink` be sure to pass `@hasChildLabel={{false}}` to the wrapping `EuiFormRow`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiCode,
  EuiForm,
  EuiFormRow,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class FormLabelsDemo extends Component {
  @tracked checkedState = true;

  @action
  onChange() {
    this.checkedState = false;
    setTimeout(() => {
      this.checkedState = true;
    }, 500);
  }

  @action
  onSubmit(event) {
    event.preventDefault();
  }

  <template>
    <EuiForm @tagName="form" {{on "submit" this.onSubmit}}>
      <EuiFormRow @label="Settings" @hasChildLabel={{false}}>
        <:helpText>
          Navigate to this Switch with a screen reader. With
          <EuiCode>@hasChildLabel={{false}}</EuiCode> the name of this is
          &ldquo;Dark mode&rdquo; instead of &ldquo;Settings&rdquo;.
        </:helpText>
        <:field>
          <EuiSwitch
            name="switch"
            @label="Dark mode"
            @onChange={{this.onChange}}
            @checked={{this.checkedState}}
          />
        </:field>
      </EuiFormRow>

      <EuiFormRow @label="Your cluster data" @hasChildLabel={{false}}>
        <:helpText>
          Navigate to this button with a screen reader. With
          <EuiCode>@hasChildLabel={{false}}</EuiCode> the name of this button
          is &ldquo;Download&rdquo; instead of &ldquo;Your cluster data&rdquo;.
        </:helpText>
        <:field>
          <EuiButton>Download</EuiButton>
        </:field>
      </EuiFormRow>
    </EuiForm>
  </template>
}
```
