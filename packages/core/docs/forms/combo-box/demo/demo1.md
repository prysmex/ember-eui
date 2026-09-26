---
order: 1
---

# Multiple selection and custom options

<EuiText>

The default combo box selects several options, shown as removable pills.
With `@onCreateOption`, typing a value that doesn't exist offers to add
it: create the option and select it in your handler. `@closeOnSelect={{false}}`
keeps the list open to pick several options in a row.

</EuiText>

```hbs template
<EuiComboBox
  @onChange={{this.onChange}}
  @options={{this.remainingOptions}}
  @selectedOptions={{this.selected}}
  @searchEnabled={{true}}
  @closeOnSelect={{false}}
  @searchField='label'
  @placeholder='Select options'
  @removeTag={{this.removeOption}}
  @onCreateOption={{this.onCreateOption}}
  @alwaysShowCreateOption={{false}}
  as |option item|
>
  {{option.label}}
</EuiComboBox>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked selected = [];
  @tracked options = [];
  @tracked remainingOptions = [];
  constructor() {
    super(...arguments);
    this.options = this.generateArray(100);
    this.remainingOptions = this.options.slice();
  }
  generateArray(n) {
    let arr = [];
    for (let i = 0; i < n - 1; i++) {
      arr[i] = {
        value: i,
        label: `Number ${i}`,
        color: '#' + (((1 << 24) * Math.random()) | 0).toString(16)
      };
    }
    return arr;
  }

  @action
  calculateRemainingOptions() {
    this.remainingOptions = this.options.filter(
      (opt) => !this.selected.includes(opt)
    );
  }

  @action
  onChange(selected) {
    this.selected = selected;
    this.calculateRemainingOptions();
  }

  @action
  onCreateOption(str) {
    let newOption = {
      value: this.options.length + 1,
      label: str,
      color: '#' + (((1 << 24) * Math.random()) | 0).toString(16)
    };
    this.options = [...this.options, newOption];
    this.selected = [...this.selected, newOption];
    this.calculateRemainingOptions();
  }

  @action
  removeOption(opt) {
    this.selected = this.selected.filter((p) => {
      return p !== opt;
    });

    this.calculateRemainingOptions();
  }
}
```
