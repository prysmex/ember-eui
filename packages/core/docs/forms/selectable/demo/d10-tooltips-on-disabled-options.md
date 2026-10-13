---
order: 10
---

# Tooltips on disabled options

<EuiText>

To add tooltips on disabled options, set `hasAriaDisabled: true` alongside `disabled: true` on the option. This keeps the option focusable but excluded from selection. This is useful for communicating _why_ an option is unavailable.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable } from '@ember-eui/core/components';

export default class SelectableDisabledTooltipsDemo extends Component {
  @tracked options = [
    { label: 'Titan' },
    {
      label: 'Enceladus',
      disabled: true,
      hasAriaDisabled: true,
      toolTipContent: 'Enceladus is currently unavailable',
    },
    { label: 'Mimas', checked: 'on' },
    { label: 'Dione' },
    {
      label: 'Iapetus',
      disabled: true,
      hasAriaDisabled: true,
      toolTipContent: 'Iapetus requires elevated permissions',
    },
  ];

  @action
  setOptions(options) {
    this.options = options;
  }

  <template>
    <EuiSelectable
      aria-label="Example with disabled options and tooltips"
      @options={{this.options}}
      @onChange={{this.setOptions}}
    />
  </template>
}
```
