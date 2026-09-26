---
order: 1
---

# Switch

<EuiText>

`@onChange` receives the click event; `event.target.checked` is the new
state.

</EuiText>

```hbs template
<EuiSwitch
  @label="Auto-refresh"
  @checked={{this.autoRefresh}}
  @onChange={{this.toggle}}
/>
<EuiSpacer />
<EuiSwitch @label="Compressed" @compressed={{true}} @checked={{true}} />
<EuiSpacer />
<EuiSwitch @label="Disabled" @disabled={{true}} @checked={{false}} />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SwitchDemo extends Component {
  @tracked autoRefresh = true;

  @action
  toggle(event) {
    this.autoRefresh = event.target.checked;
  }
}
```
