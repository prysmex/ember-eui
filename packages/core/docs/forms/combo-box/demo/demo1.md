---
order: 1
---

<EuiText>
  <p>
    <strong>EuiComboBox </strong> ember's implementation uses <a href="https://ember-power-select.com">ember-power-select</a> under the hood for a rich selector, so please refer to it if needed.
  </p>
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
  onChange(selected) {
    this.remainingOptions = this.options.filter(
      (opt) => !selected.includes(opt)
    );
    this.selected = selected;
  }
}
```
