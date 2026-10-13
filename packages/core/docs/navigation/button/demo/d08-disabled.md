---
order: 8
---

# Disabled

<EuiText>

Show a button in a disabled state when the action **cannot be performed** due to permissions, licensing, or data issues (e.g., invalid input). Consider whether the user needs to know the button exists; showing it indicates potential actions, while hiding it may lead to unawareness. Only hide buttons when the action's potential is immaterial. Do not show disabled buttons if the user is unlikely to perform the action. All button types have the same disabled state.

</EuiText>

```hbs template
<EuiSwitch @compressed={{true}} @label="Disabled" @checked={{this.disableButton}} @onChange={{this.toggle}} />
<EuiSpacer />
<EuiButton @isDisabled={{this.disableButton}} @fill={{true}}>
  {{if this.disableButton "Disabled" "Button"}}
</EuiButton>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoComponent extends Component {
  @tracked disableButton = true;

  @action
  toggle() {
    this.disableButton = !this.disableButton;
  }
}
```
