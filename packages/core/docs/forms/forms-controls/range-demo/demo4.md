---
order: 4
---

# Demo

```hbs template
<EuiTitle>
  Tick marks
</EuiTitle>
<EuiText>
  <p>
    To show clickable tick marks and labels at a given interval, add the prop showTicks. By default, tick mark interval is bound to the step prop, however, you can set a custom interval without changing the actual steps allowed by passing a number to the tickInterval prop.
  </p>
  <p>
    To pass completely custom tick marks, you can pass an array of objects that require a value and label. The value must be included in the range of values (min-max), though the label may be anythin you choose.
  </p>
</EuiText>
<EuiRange
  @step={{10}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showTicks={{true}}
  aria-label="An example of EuiRange with ticks"
/>
<EuiSpacer @size="xl" />
<EuiTitle @size="xxs">
  <h3>
    Custom tick interval
  </h3>
</EuiTitle>
<EuiSpacer @size="l" />
<EuiRange
  @value={{this.value2}}
  @onChange={{this.onChange2}}
  @showInput={{true}}
  @showRange={{true}}
  @showTicks={{true}}
  @tickInterval={{20}}
  aria-label="An example of EuiRange with custom tickInterval"
/>
<EuiSpacer @size="xl" />
<EuiTitle @size="xxs">
  <h3>
    Custom ticks object
  </h3>
</EuiTitle>
<EuiSpacer @size="l" />
<EuiDualRange
  @value={{this.dualValue}}
  @onChange={{set this.dualValue}}
  @ticks={{array (hash label="20kb" value=20) (hash label="100kb" value=100)}}
  @showInput={{true}}
  @showTicks={{true}}
  aria-label="An example of EuiDualRange with ticks"
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked value = '20';
  @tracked dualValue = [20, 100];

  @action
  onChange(e) {
    this.value = e.target.value;
  }

  @tracked value2 = '20';
  @action
  onChange2(e) {
    this.value2 = e.target.value;
  }
}
```
