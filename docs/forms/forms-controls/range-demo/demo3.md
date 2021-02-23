---
order: 3
---

# Demo

```hbs template
<EuiTitle>
  Inputs
</EuiTitle>
<EuiText>
  <p>
    The showInput prop, will append or bookend the range slider with number type inputs. This is important for allowing precise values to be entered by the user.
  </p>
  <p>
    Passing empty strings as the value to the ranges, will allow the inputs to be blank, though the range handles will show at the min (or max and min) positions.
  </p>
</EuiText>
<EuiRange
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showInput={{true}}
  aria-label="An example of EuiRange"
/>
<EuiSpacer @size="xl" />
<EuiDualRange
  @value={{this.valueDual}}
  @onChange={{this.onChangeDual}}
  @showInput={{true}}
  @minInputProps={{hash ariaLabel="Min Value"}}
  @maxInputProps={{hash ariaLabel="Max Value"}}
  aria-label="An example of EuiDualRange with inputs"
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
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
}
```
