---
order: 1
---

# Basic text field

<EuiText>

Pass the value as `@value` and update it on `input`. Attributes such as
`placeholder` go to the `<input>`.

</EuiText>

```hbs template
<EuiFieldText
  @value={{this.name}}
  placeholder="Type your name"
  aria-label="Name"
  {{on "input" this.updateName}}
/>
<EuiSpacer @size="s" />
<EuiText @size="s" @color="subdued">
  <p>Hello {{if this.name this.name "stranger"}}!</p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class BasicTextFieldDemo extends Component {
  @tracked name = '';

  @action
  updateName(event) {
    this.name = event.target.value;
  }
}
```
