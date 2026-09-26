---
order: 1
---

# Checkbox

<EuiText>

Keep the checked state and update it on `change`. Clicking the label
toggles the checkbox too.

</EuiText>

```hbs template
<EuiCheckbox
  @label="Send me product updates"
  @checked={{this.updates}}
  {{on "change" this.toggleUpdates}}
/>
<EuiCheckbox @label="Disabled" @disabled={{true}} />
<EuiCheckbox @label="Disabled and checked" @disabled={{true}} @checked={{true}} />
<EuiCheckbox @label="Compressed" @compressed={{true}} @checked={{true}} />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CheckboxDemo extends Component {
  @tracked updates = true;

  @action
  toggleUpdates(event) {
    this.updates = event.target.checked;
  }
}
```
