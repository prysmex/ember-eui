---
order: 2
---

# Your own objects

<EuiText>

With `@valueKey` and `@labelKey` the group reads the id and label from any
key, so you can pass your records directly. Inside an `EuiFormRow`, the
row's label names the group; `@compressed` tightens the spacing.

</EuiText>

```hbs template
<EuiFormRow @label="Notify" @labelType="legend" @legendType="legend">
  <EuiCheckboxGroup
    @options={{this.users}}
    @valueKey="email"
    @labelKey="name"
    @idToSelectedMap={{this.selected}}
    @compressed={{true}}
    @onChange={{this.toggle}}
  />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CheckboxGroupKeysDemo extends Component {
  users = [
    { email: 'jane@example.com', name: 'Jane' },
    { email: 'raj@example.com', name: 'Raj' },
    { email: 'li@example.com', name: 'Li' },
  ];

  @tracked selected = { 'raj@example.com': true };

  @action
  toggle(email) {
    this.selected = { ...this.selected, [email]: !this.selected[email] };
  }
}
```
