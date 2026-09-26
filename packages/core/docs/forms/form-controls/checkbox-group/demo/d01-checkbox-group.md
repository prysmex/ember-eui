---
order: 1
---

# Checkbox group

<EuiText>

`@onChange` receives the id of the checkbox that was clicked; flip it in
`@idToSelectedMap`. Replace the map (don't mutate it) so the group updates.

</EuiText>

```hbs template
<EuiCheckboxGroup
  @legend="Toppings"
  @options={{this.toppings}}
  @idToSelectedMap={{this.selected}}
  @onChange={{this.toggle}}
/>
<EuiSpacer />
<EuiText @size="s" @color="subdued">
  <p>Selected: {{this.summary}}</p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CheckboxGroupDemo extends Component {
  toppings = [
    { id: 'cheese', label: 'Extra cheese' },
    { id: 'olives', label: 'Olives' },
    { id: 'mushrooms', label: 'Mushrooms' },
    { id: 'pineapple', label: 'Pineapple', disabled: true },
  ];

  @tracked selected = { cheese: true };

  get summary() {
    const names = this.toppings.filter((t) => this.selected[t.id]).map((t) => t.label);

    return names.length ? names.join(', ') : 'nothing';
  }

  @action
  toggle(id) {
    this.selected = { ...this.selected, [id]: !this.selected[id] };
  }
}
```
