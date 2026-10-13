---
order: 1
---

# Basic number field

<EuiText>

Use an `EuiFieldNumber` to allow users to enter numbers. It renders a basic HTML `<input type="number">` element. Convert the event's value to a number yourself; an empty field gives `''`.

The switches above the field are docs-only helpers that toggle its display arguments.

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
<EuiFieldNumber
  @value={{this.value}}
  placeholder="Placeholder text"
  @fullWidth={{this.flags.fullWidth}}
  @compressed={{this.flags.compressed}}
  @isInvalid={{this.flags.isInvalid}}
  @isLoading={{this.flags.isLoading}}
  @readOnly={{this.flags.readOnly}}
  @disabled={{this.flags.disabled}}
  aria-label="Use aria labels when no actual label is in use"
  {{on "input" this.onChange}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class NumberFieldDemo extends Component {
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
