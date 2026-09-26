---
order: 2
---

# In a form row, with your own objects

<EuiText>

Inside an `EuiFormRow`, use `@labelType="legend"` and `@legendType="legend"`
so the row's label names the group. `@valueKey` / `@labelKey` read your
objects' keys, and `@compressed` fits dense forms.

</EuiText>

```hbs template
<EuiFormRow @label="Assignee" @labelType="legend" @legendType="legend">
  <EuiRadioGroup
    @name="assignee"
    @options={{this.users}}
    @valueKey="username"
    @labelKey="name"
    @idSelected={{this.assignee}}
    @compressed={{true}}
    @onChange={{this.assign}}
  />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class RadioGroupKeysDemo extends Component {
  users = [
    { username: 'jane', name: 'Jane Cooper' },
    { username: 'raj', name: 'Raj Patel' },
  ];

  @tracked assignee = 'raj';

  @action
  assign(username) {
    this.assignee = username;
  }
}
```
