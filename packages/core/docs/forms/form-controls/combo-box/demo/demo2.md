---
order: 2
---

# Disabled

<EuiText>
	<p>
		Set the prop <EuiCode> isDisabled </EuiCode> to make the combo box disabled.
	</p>
</EuiText>

```hbs template
<EuiComboBox
  @onChange={{this.onChange}}
  @options={{this.remainingOptions}}
  @selectedOptions={{this.selected}}
  @searchEnabled={{true}}
  @isDisabled={{true}}
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
  @tracked remainingOptions = [];
  constructor() {
    super(...arguments);
    this.options = this.generateArray(100);
    this.remainingOptions = this.options.slice();
    this.selected = [this.options[0]];
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
