---
order: 1
---

# Colored options

<EuiText>

Options with a colored dot (`EuiHealth`), rendered by the blocks. The
last option is disabled.

</EuiText>

```hbs template
<EuiFormRow @label="Status">
  <EuiSuperSelect
    @options={{this.options}}
    @valueOfSelected={{this.value}}
    @onChange={{this.setValue}}
  >
    <:inputDisplay as |option|>
      <EuiHealth @color={{option.color}}>{{option.inputDisplay}}</EuiHealth>
    </:inputDisplay>
    <:dropdownDisplay as |option|>
      <EuiHealth @color={{option.color}}>{{option.inputDisplay}}</EuiHealth>
    </:dropdownDisplay>
  </EuiSuperSelect>
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SuperSelectDemo extends Component {
  @tracked value = 'warning';

  options = [
    { value: 'healthy', inputDisplay: 'Healthy', color: 'success' },
    { value: 'warning', inputDisplay: 'Warning', color: 'warning' },
    { value: 'critical', inputDisplay: 'Critical', color: 'danger' },
    { value: 'unknown', inputDisplay: 'Unknown', color: 'subdued', disabled: true },
  ];

  @action
  setValue(value) {
    this.value = value;
  }
}
```
