---
order: 1
---

# Super select

<EuiText>

`EuiSuperSelect` is a flexible alternative to `EuiSelect` that lets you customize the input and option displays. Provide an array of option objects with:

- `value`: a unique value for each item,
- `inputDisplay`: what appears in the input when selected,
- `dropdownDisplay`: (optional) custom content for multi-line option text or descriptions.

For markup, use the `<:inputDisplay>` and `<:dropdownDisplay>` named blocks: they are called with each option. The component creates a select-style button that opens a popover with selectable items.

For more details on which selection component to use, see the selection overview.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiSuperSelect, EuiHealth } from '@ember-eui/core/components';

export default class SuperSelectDemo extends Component {
  options = [
    { value: 'warning', label: 'Warning', color: 'subdued', disabled: true },
    { value: 'minor', label: 'Minor', color: 'warning' },
    { value: 'critical', label: 'Critical', color: 'danger' },
  ];

  @tracked value = 'minor';

  @action
  onChange(value) {
    this.value = value;
  }

  <template>
    <EuiFormRow
      @label="Status"
      @helpText="This super select is inside a form row."
    >
      <EuiSuperSelect
        @options={{this.options}}
        @valueOfSelected={{this.value}}
        @onChange={{this.onChange}}
      >
        <:inputDisplay as |option|>
          <EuiHealth @color={{option.color}} style="line-height: inherit">
            {{option.label}}
          </EuiHealth>
        </:inputDisplay>
        <:dropdownDisplay as |option|>
          <EuiHealth @color={{option.color}} style="line-height: inherit">
            {{option.label}}
          </EuiHealth>
        </:dropdownDisplay>
      </EuiSuperSelect>
    </EuiFormRow>
  </template>
}
```
