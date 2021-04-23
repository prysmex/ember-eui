---
order: 2
---

# Demo

Using on create options for bubbling new option and handling in onCreateOption function, you may want to provide a customOptionText, you can assume {searchText} will be interpolated, be sure sanitize your string!

```hbs template
	<EuiComboBox
		@onChange={{this.onChange}}
		@options={{this.remainingOptions}}
    @onCreateOption={{this.onCreateOption}}
		@selectedOptions={{this.selected}}
		@searchEnabled={{true}}
    @customOptionText="Do you want to add&nbsp;{searchText}&nbsp;to your list?"
    @searchField="label"
	as |option item|>
		{{option.label}}
	</EuiComboBox>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class Demo1 extends Component {
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
  onChange(selected) {
    this.remainingOptions = this.options.filter(
      (opt) => !selected.includes(opt)
    );
    this.selected = selected;
  }

  @action
  onCreateOption(newOption) {
    const newOptionStructure = {
      value: `${newOption}`,
      label: `${newOption}`
    }
    if(this.options.filter( opt => opt.value == newOptionStructure.value).length == 0){
      this.options.addObject(newOptionStructure)
      this.selected.addObject(newOptionStructure)
    }
  }
}
```
