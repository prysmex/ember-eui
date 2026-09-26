---
order: 1
---

# Form rows

<EuiText>

A form row with a label, help text and an error. The error shows only while
`@isInvalid` is true, and the label turns red with it. Pass `@isInvalid` to
the control as well, to style it and mark it invalid for the browser.

</EuiText>

```hbs template
<EuiFormRow
  @label="Username"
  @helpText="Between 3 and 20 characters, no spaces."
  @isInvalid={{this.isInvalid}}
  @error="Usernames can't contain spaces."
>
  <EuiFieldText
    @value={{this.username}}
    @isInvalid={{this.isInvalid}}
    {{on "input" this.updateUsername}}
  />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class FormRowDemo extends Component {
  @tracked username = 'jane doe';

  get isInvalid() {
    return this.username.includes(' ');
  }

  @action
  updateUsername(event) {
    this.username = event.target.value;
  }
}
```
