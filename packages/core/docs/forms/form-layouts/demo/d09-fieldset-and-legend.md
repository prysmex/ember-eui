---
order: 9
---

# Fieldset and legend

<EuiText>

Use `EuiFormFieldset` for groups of related controls where the individual labels for each control do not provide a sufficient description and an additional group level description is needed ([accessible name](https://www.w3.org/WAI/WCAG21/Techniques/html/H71)).

`EuiFormFieldset` wraps its children in a `<fieldset>` with the option to add a `<legend>` via `@legend`. While most commonly used for checkboxes and radios, it can also be used to group related inputs and selects under a shared label.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiFormFieldset,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class FieldsetLegendDemo extends Component {
  @tracked object1 = false;
  @tracked object2 = true;

  @action
  toggle1(event) {
    this.object1 = event.target.checked;
  }

  @action
  toggle2(event) {
    this.object2 = event.target.checked;
  }

  <template>
    <EuiFormFieldset @legend="Enable these objects">
      <EuiSwitch @label="Object 1" @onChange={{this.toggle1}} @checked={{this.object1}} />
      <EuiSpacer @size="s" />
      <EuiSwitch @label="Object 2" @onChange={{this.toggle2}} @checked={{this.object2}} />
    </EuiFormFieldset>
  </template>
}
```
