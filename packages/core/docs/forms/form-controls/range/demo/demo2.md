---
order: 2
---

# Dual range

<EuiText>
  <p>
    The <strong>EuiDualRange</strong> accepts almost all the same props
    as the regular <strong>EuiRange</strong>, with the exception of
    <EuiCode>@showRange</EuiCode> which is on by default, and
    <EuiCode>@showValue</EuiCode> since tooltips don't fit properly
    when there are two.
  </p>
  <EuiCallOut @color="warning" @title="Retrieving field values">
    <:body>
      <p>
        Two-value <EuiCode @language="html">input[type=range]</EuiCode> elements are not
        part of the HTML5 specification. Because of this support gap,
        <strong>EuiDualRange</strong> cannot expose a native
        <EuiCode>value</EuiCode> property for native form to consumption.
        <strong>
          <EuiCode>@onChange</EuiCode> is the recommended
          method for retrieving the upper and lower values.
        </strong>
      </p>
      <p>
        <strong>EuiDualRange</strong> does use native inputs to help
        validate step values and range limits. These may be used as form
        values when <EuiCode>@showInput</EuiCode> is in use. The
        alternative is to store values in
        <EuiCode @language="html">input[type=hidden]</EuiCode>.
      </p>
    </:body>
  </EuiCallOut>
</EuiText>

```hbs template
<EuiDualRange
  @value={{this.value}}
  @min={{-100}}
  @max={{200}}
  @step={{10}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  aria-label='An example of EuiDualRange'
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked value = ['', ''];
  @action
  onChange(values) {
    this.value = values;
  }
}
```
