---
order: 1
---

# Radio group

<EuiText>

`@onChange` receives the chosen option's id; set `@idSelected` to it. A
`disabled` option can't be chosen; `@disabled` disables the whole group.

</EuiText>

```hbs template
<EuiRadioGroup
  @legend="Delivery"
  @name="delivery"
  @options={{this.options}}
  @idSelected={{this.selected}}
  @onChange={{this.select}}
/>
<EuiSpacer />
<EuiText @size="s" @color="subdued"><p>Selected: {{this.selected}}</p></EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class RadioGroupDemo extends Component {
  options = [
    { id: 'standard', label: 'Standard (3–5 days)' },
    { id: 'express', label: 'Express (1–2 days)' },
    { id: 'drone', label: 'Drone (not available yet)', disabled: true },
  ];

  @tracked selected = 'standard';

  @action
  select(id) {
    this.selected = id;
  }
}
```
