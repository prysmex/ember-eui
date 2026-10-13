---
order: 2
---

# Without a visible label

<EuiText>

If the switch is described in some other manner, like when using an `EuiFormRow`, you can eliminate the visible label with `@showLabel={{false}}` or use it to further describe the state.

When providing the state as the label, you'll need to provide an `aria-describedby` with the label's `id` to associate it with the switch.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiSwitch } from '@ember-eui/core/components';

export default class SwitchHiddenLabelDemo extends Component {
  @tracked checked1 = false;
  @tracked checked2 = false;

  @action
  onChange1(event) {
    this.checked1 = event.target.checked;
  }

  @action
  onChange2(event) {
    this.checked2 = event.target.checked;
  }

  <template>
    <EuiFormRow @display="columnCompressed" @label="Autoscaling">
      <EuiSwitch
        @showLabel={{false}}
        @label="Autoscaling"
        @checked={{this.checked1}}
        @onChange={{this.onChange1}}
        @compressed={{true}}
      />
    </EuiFormRow>
    <EuiFormRow @display="columnCompressed">
      <:label>
        <span id="toggleTextSwitch">Show something</span>
      </:label>
      <:field>
        <EuiSwitch
          @label={{if this.checked2 "on" "off"}}
          @checked={{this.checked2}}
          @onChange={{this.onChange2}}
          @compressed={{true}}
          aria-describedby="toggleTextSwitch"
        />
      </:field>
    </EuiFormRow>
  </template>
}
```
