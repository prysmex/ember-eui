---
order: 2
---

# Demo

```hbs template
<EuiTitle>
  Dual range
</EuiTitle>
<EuiText>
  <p>
    The EuiDualRange accepts almost all the same props as the regular EuiRange, with the exception of showRange which is on by default, and showValue since tooltips don't fit properly when there are two.
  </p>
</EuiText>
<EuiCallOut @color="warning" @title="Retrieving field values">
  <:title>
    Retrieving field values
  </:title>
  <:body>
    <p>
      Two-value input[type=range] elements are not part of the HTML5 specification. Because of this support gap, EuiDualRange cannot expose a native value property for native form to consumption. The React onChange prop is the recommended method for retrieving the upper and lower values.
    </p>
    <p>
      EuiDualRange does use native inputs to help validate step values and range limits. These may be used as form values when showInput is in use. The alternative is to store values in input[type=hidden].
    </p>
  </:body>
</EuiCallOut>
<EuiTitle>
  Values: [
  {{object-at "0" this.value}}
  ,
  {{object-at "1" this.value}}
  ]
</EuiTitle>
<EuiDualRange
  @value={{this.value}}
  @min={{-100}}
  @max={{200}}
  @step={{10}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  aria-label="An example of EuiDualRange"
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked value = ['', ''];
  @action
  onChange(values) {
    console.log(values);
    this.value = values;
  }
}
```
