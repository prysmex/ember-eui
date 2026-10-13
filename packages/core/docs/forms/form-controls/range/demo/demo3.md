---
order: 3
---

# Inputs

<EuiText>
  <p>
    The <EuiCode>@showInput</EuiCode> arg, will append or bookend the range slider with number type inputs. This is important for allowing precise values to be entered by the user.
  </p>
  <p>
    Passing empty strings as the value to the ranges, will allow the inputs to be blank, though the range handles will show at the min (or max and min) positions.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiRange, EuiSpacer, EuiDualRange } from '@ember-eui/core/components';

export default class 3Demo extends Component {
  @tracked value = '20';
  @tracked valueDual = [20, 100];

  @action
  onChange(e) {
    this.value = e.target.value;
  }

  @action
  onChangeDual(values) {
    this.valueDual = values;
  }

  <template>
    <EuiRange
      @value={{this.value}}
      @onChange={{this.onChange}}
      @showInput={{true}}
      aria-label='An example of EuiRange'
    />
    <EuiSpacer @size='xl' />
    <EuiDualRange
      @value={{this.valueDual}}
      @onChange={{this.onChangeDual}}
      @showInput={{true}}
      aria-label='An example of EuiDualRange with inputs'
    />
  </template>
}
```
