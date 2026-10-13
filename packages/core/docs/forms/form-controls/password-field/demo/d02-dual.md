---
order: 2
---

# Showing passwords

<EuiText>

You can allow users to toggle between showing and obfuscating the password by passing `@type="dual"` (the default). This option makes the experience more user-friendly and accessible.

</EuiText>

```hbs template
<EuiFlexGroup @wrap={{true}} @gutterSize="m" @responsive={{false}}>
  {{#each this.toggles as |toggle|}}
    <EuiFlexItem @grow={{false}}>
      <EuiSwitch
        @label={{toggle.label}}
        @compressed={{true}}
        @checked={{get this.flags toggle.key}}
        @onChange={{fn this.toggle toggle.key}}
      />
    </EuiFlexItem>
  {{/each}}
</EuiFlexGroup>
<EuiSpacer @size="m" />
<EuiFieldPassword
  @type="dual"
  @value={{this.value}}
  placeholder="Password"
  @fullWidth={{this.flags.fullWidth}}
  @compressed={{this.flags.compressed}}
  @isInvalid={{this.flags.isInvalid}}
  @isLoading={{this.flags.isLoading}}
  @readOnly={{this.flags.readOnly}}
  @disabled={{this.flags.disabled}}
  aria-label="Password that can be toggled between hidden and shown"
  {{on "input" this.onChange}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PasswordFieldDualDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'readOnly', label: 'readOnly' },
    { key: 'disabled', label: 'disabled' },
  ];

  @tracked flags = {};
  @tracked value = '';

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  onChange(event) {
    this.value = event.target.value;
  }
}
```
