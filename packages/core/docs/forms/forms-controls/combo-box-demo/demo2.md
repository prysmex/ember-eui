---
order: 2
---

# Demo

```hbs template
	<EuiComboBox
		@onChange={{this.onChange}}
		@options={{this.remainingOptions}}
		@selectedOptions={{this.selected}}
		@searchEnabled={{true}}
		@singleSelection={{hash asPlainText=true}}
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
}
```
