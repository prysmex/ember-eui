---
order: 2
---

# More complex

<EuiText>

Both the `<:inputDisplay>` and `<:dropdownDisplay>` blocks accept any markup. Therefore you can pass some descriptions with each option to show in the dropdown.

A `@placeholder` argument may also be passed. This placeholder will only show when `@valueOfSelected` is empty.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSuperSelect, EuiText } from '@ember-eui/core/components';

export default class SuperSelectComplexDemo extends Component {
  options = [
    { value: 'option_one', inputDisplay: 'Option one' },
    { value: 'option_two', inputDisplay: 'Option two' },
    { value: 'option_three', inputDisplay: 'Option three' },
  ];

  @tracked value;

  @action
  onChange(value) {
    this.value = value;
  }

  <template>
    <EuiSuperSelect
      @options={{this.options}}
      @valueOfSelected={{this.value}}
      @placeholder="Select an option"
      @onChange={{this.onChange}}
    >
      <:dropdownDisplay as |option|>
        <strong>{{option.inputDisplay}}</strong>
        <EuiText @size="s" @color="subdued">
          <p>Has a short description giving more detail to the option.</p>
        </EuiText>
      </:dropdownDisplay>
    </EuiSuperSelect>
  </template>
}
```
