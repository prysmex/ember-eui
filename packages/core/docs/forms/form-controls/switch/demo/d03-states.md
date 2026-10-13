---
order: 3
---

# Switch states

<EuiText>

`@onChange` receives the click event; `event.target.checked` is the new
state.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSwitch, EuiSpacer } from '@ember-eui/core/components';

export default class SwitchStatesDemo extends Component {
  @tracked autoRefresh = true;

  @action
  toggle(event) {
    this.autoRefresh = event.target.checked;
  }

  <template>
    <EuiSwitch
      @label="Auto-refresh"
      @checked={{this.autoRefresh}}
      @onChange={{this.toggle}}
    />
    <EuiSpacer />
    <EuiSwitch @label="Compressed" @compressed={{true}} @checked={{true}} />
    <EuiSpacer />
    <EuiSwitch @label="Disabled" @disabled={{true}} @checked={{false}} />
  </template>
}
```
