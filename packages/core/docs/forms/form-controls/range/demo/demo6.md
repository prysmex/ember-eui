---
order: 6
---

# Inputs with range in a dropdown

<EuiText>
  <p>
    Passing <EuiCode>@showInput="inputWithPopover"</EuiCode> instead of a boolean will only display the inputs until the input is interacted with in which case a dropdown will appear displaying the actual slider.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiRange, EuiSpacer, EuiDualRange } from '@ember-eui/core/components';
import { set } from 'ember-set-helper';

export default class 6Demo extends Component {
  @tracked value = '20';
  @action
  onChange(e) {
    this.value = e.target.value;
  }

  levels = [
    {
      min: 0,
      max: 20,
      color: 'danger'
    },
    {
      min: 20,
      max: 100,
      color: 'success'
    }
  ];

  <template>
    <EuiRange
      @value={{this.value}}
      @onChange={{this.onChange}}
      @showInput='inputWithPopover'
      @showLabels={{true}}
      aria-label='An example of EuiRange with showInput prop'
    />
    <EuiSpacer @size='xl' />
    <EuiDualRange
      @value={{this.dualValue}}
      @onChange={{set this 'dualValue'}}
      @showInput='inputWithPopover'
      @showLabels={{true}}
      @levels={{this.levels}}
      aria-label='An example of EuiDualRange with showInput prop'
    />
  </template>
}
```
