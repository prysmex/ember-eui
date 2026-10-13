---
order: 3
---

# Virtualized

<EuiText>

`EuiComboBox` uses a virtualized list to only render visible options to be super fast no matter how many options there are.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiComboBox } from '@ember-eui/core/components';

const OPTIONS = [];
let groupOptions = [];

for (let i = 1; i < 5000; i++) {
  groupOptions.push({ label: `option${i}` });

  if (i % 25 === 0) {
    OPTIONS.push({
      groupName: `Options ${i - (groupOptions.length - 1)} to ${i}`,
      options: groupOptions,
    });
    groupOptions = [];
  }
}

export default class ComboBoxVirtualizedDemo extends Component {
  options = OPTIONS;

  @tracked selectedOptions = [];

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  <template>
    <EuiComboBox
      @ariaLabel="Accessible screen reader label"
      @placeholder="Select one or more options"
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
