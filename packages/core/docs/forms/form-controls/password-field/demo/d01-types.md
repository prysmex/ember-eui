---
order: 1
---

# Show or hide the password

<EuiText>

`@type="dual"` (the default) adds a button that shows the password;
`"password"` always hides it; `"text"` always shows it.

</EuiText>

```hbs template
<EuiFormRow @label="Password (dual, the default)">
  <EuiFieldPassword
    @value={{this.password}}
    autocomplete="new-password"
    {{on "input" this.updatePassword}}
  />
</EuiFormRow>
<EuiFormRow @label="Always hidden">
  <EuiFieldPassword @type="password" @value={{this.password}} />
</EuiFormRow>
<EuiFormRow @label="Always shown">
  <EuiFieldPassword @type="text" @value={{this.password}} />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PasswordTypesDemo extends Component {
  @tracked password = 'correct horse battery staple';

  @action
  updatePassword(event) {
    this.password = event.target.value;
  }
}
```
