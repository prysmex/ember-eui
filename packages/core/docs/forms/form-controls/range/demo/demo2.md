---
order: 2
---

# Dual range

<EuiText>
  <p>
    The <strong>EuiDualRange</strong> accepts almost all the same arguments
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
        <EuiCode>@value</EuiCode> property for native form to consumption.
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

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiDualRange,
  EuiSpacer,
  EuiTitle,
} from '@ember-eui/core/components';

export default class Range2Demo extends Component {
  @tracked dualValue = ['100', '150'];
  @tracked dualValue2 = ['40', '60'];

  @action
  onDualChange(value) {
    this.dualValue = value;
  }

  @action
  onDualChange2(value) {
    this.dualValue2 = value;
  }

  <template>
    <EuiDualRange
      @min={{0}}
      @max={{300}}
      @step={{10}}
      @value={{this.dualValue}}
      @onChange={{this.onDualChange}}
      @showLabels={{true}}
      aria-label="An example of EuiDualRange"
    />
    <EuiSpacer @size="xl" />
    <EuiTitle @size="xxs">
      <h3>Draggable highlight area</h3>
    </EuiTitle>
    <EuiSpacer @size="l" />
    <EuiDualRange
      @min={{0}}
      @max={{100}}
      @step={{1}}
      @value={{this.dualValue2}}
      @onChange={{this.onDualChange2}}
      @showLabels={{true}}
      @isDraggable={{true}}
      aria-label="An example of EuiDualRange with isDraggable='true'"
    />
  </template>
}
```
