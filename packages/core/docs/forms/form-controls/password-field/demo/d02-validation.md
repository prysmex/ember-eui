---
order: 2
---

# Validation

<EuiText>

Check the value as the user types and show what is missing in the row's
error.

</EuiText>

```hbs template
<EuiFormRow
  @label="New password"
  @helpText="At least 8 characters, with a number."
  @isInvalid={{this.isInvalid}}
  @error={{this.errors}}
>
  <EuiFieldPassword
    @value={{this.password}}
    @isInvalid={{this.isInvalid}}
    autocomplete="new-password"
    {{on "input" this.updatePassword}}
  />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PasswordValidationDemo extends Component {
  @tracked password = 'short';

  get errors() {
    const errors = [];

    if (this.password.length < 8) errors.push('Use at least 8 characters.');
    if (!/\d/.test(this.password)) errors.push('Add a number.');

    return errors;
  }

  get isInvalid() {
    return this.password !== '' && this.errors.length > 0;
  }

  @action
  updatePassword(event) {
    this.password = event.target.value;
  }
}
```
