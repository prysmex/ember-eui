---
order: 2
---

# Without a visible label

<EuiText>

When the context already names the setting (e.g. a table column or an
`EuiFormRow` label), hide the switch's own label with
`@showLabel={{false}}`. It is still read by screen readers, so keep it
descriptive.

</EuiText>

```hbs template
<EuiFormRow @label="Dark mode" @display="columnCompressedSwitch">
  <EuiSwitch
    @label="Dark mode"
    @showLabel={{false}}
    @compressed={{true}}
    @checked={{this.dark}}
    @onChange={{this.toggle}}
  />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SwitchHiddenLabelDemo extends Component {
  @tracked dark = false;

  @action
  toggle(event) {
    this.dark = event.target.checked;
  }
}
```
