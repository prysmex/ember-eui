---
order: 1
---

# Demo

This component is different yet simplier from what you'd expect in ember in a way that you don't control the rendering of each checkbox, you just pass in an array of `@options` and `@idToSelectedMap` which you are in charge to calculate on subsequent `@onChange`'s, refer to the javascript snippet.

You can optionally pass `@valueKey` and `@labelKey` for a more flexible and ergonomic API, so you don't actually _have_ to map your options to
`{ id: '', label: '' }` which are the default `@valueKey` and `@labelKey`.

<EuiSpacer />

```hbs template
<EuiCheckboxGroup
  @options={{this.checkboxes}}
  @idToSelectedMap={{this.checkboxIdToSelectedMap}}
  @valueKey="value"
  @onChange={{this.onChange}}
/>
<EuiSpacer />
<EuiCheckboxGroup
  @legend="With legend"
  @options={{this.checkboxes}}
  @idToSelectedMap={{this.checkboxIdToSelectedMap}}
  @valueKey="value"
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
      value: 'check-1',
      label: 'Checkbox 1'
    },
    {
      value: 'check-2',
      label: 'Checkbox 2'
    },
    {
      value: 'check-3',
      label: 'Checkbox 3'
    },
    {
      value: 'check-4',
      label: 'Checkbox 4'
    }
  ];
  @tracked checkboxIdToSelectedMap = {
    'check-1': true,
    'check-4': true
  };

  @action
  onChange(optionId) {
    const newCheckboxIdToSelectedMap = {
      ...this.checkboxIdToSelectedMap,
      ...{
        [optionId]: !this.checkboxIdToSelectedMap[optionId]
      }
    };
    this.checkboxIdToSelectedMap = newCheckboxIdToSelectedMap;
  }
}
```
