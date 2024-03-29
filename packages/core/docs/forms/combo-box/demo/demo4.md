---
order: 4
---

# Groups

You can group options together. The groups won’t match against the search value.

```hbs template
<EuiComboBox
  @onChange={{this.onChange}}
  @options={{this.groupedOptions}}
  @onCreateOption={{this.onCreateOption}}
  @selectedOptions={{this.selected}}
  @searchEnabled={{true}}
  @customOptionText='Do you want to add&nbsp;{searchText}&nbsp;to your list?'
  @searchField='label'
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
  @tracked groupedOptions = [];

  constructor() {
    super(...arguments);
    this.options = [
      { value: 'No group option', label: 'No group option', color: 'red' },
      { groupName: 'Group 1', options: this.generateArray('group1', 3) },
      { groupName: 'Group 2', options: this.generateArray('group2', 5) }
    ];
    this.groupedOptions = this.options.slice();
  }
  generateArray(prefix, n) {
    let arr = [];
    for (let i = 0; i < n - 1; i++) {
      arr[i] = {
        value: i,
        label: `${prefix} Number ${i}`,
        color: '#' + (((1 << 24) * Math.random()) | 0).toString(16)
      };
    }
    return arr;
  }

  @action
  onChange(selected) {
    this.groupedOptions = this.options.filter((opt) => !selected.includes(opt));
    this.selected = selected;
  }

  @action
  onCreateOption(newOption) {
    const newOptionStructure = {
      value: `${newOption}`,
      label: `${newOption}`
    };
    if (
      this.options.filter((opt) => opt.value == newOptionStructure.value)
        .length == 0
    ) {
      this.options.addObject(newOptionStructure);
      this.selected.addObject(newOptionStructure);
    }
  }
}
```
