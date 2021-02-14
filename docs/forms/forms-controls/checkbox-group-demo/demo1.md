---
order: 1
---

# Demo

```hbs template
<EuiCheckboxGroup
  @options={{this.checkboxes}}
  @idToSelectedMap={{this.checkboxIdToSelectedMap}}
  @onChange={{this.onChange}}
/>
<EuiSpacer />
<EuiCheckboxGroup
  @legend="With legend"
  @options={{this.checkboxes}}
  @idToSelectedMap={{this.checkboxIdToSelectedMap}}
  @onChange={{this.onChange}}
/>
<EuiSpacer />
{{#each-in this.checkboxIdToSelectedMap as |v k|}}
  <p>
    {{v}}
    :
    {{k}}
  </p>
{{/each-in}}
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  checkboxes = [
    {
      id: 'check-1',
      label: 'Checkbox 1',
    },
    {
      id: 'check-2',
      label: 'Checkbox 2',
    },
    {
      id: 'check-3',
      label: 'Checkbox 3',
    },
    {
      id: 'check-4',
      label: 'Checkbox 4',
    },
  ];
  @tracked checkboxIdToSelectedMap = {
    'check-1': true,
    'check-4': true,
  };

  @action
  onChange(optionId) {
    const newCheckboxIdToSelectedMap = {
      ...this.checkboxIdToSelectedMap,
      ...{
        [optionId]: !this.checkboxIdToSelectedMap[optionId],
      },
    };
    this.checkboxIdToSelectedMap = newCheckboxIdToSelectedMap;
  }
}
```
