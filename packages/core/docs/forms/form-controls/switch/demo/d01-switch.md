---
order: 1
---

# Switch

<EuiText>

An `EuiSwitch` can be substituted for an `EuiCheckbox` when the semantics of the label dictate a true on/off state.

Make sure to pass a `@label` to ensure a larger clickable area and ensure that screen readers will read out the label when the user is focused on the input.

The switches above the example are docs-only helpers that toggle `@compressed` and `@disabled`.

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
<EuiSwitch
  @label="Malware protection"
  @checked={{this.checked}}
  @compressed={{this.flags.compressed}}
  @disabled={{this.flags.disabled}}
  @onChange={{this.onChange}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SwitchDemo extends Component {
  toggles = [
    { key: 'compressed', label: 'compressed' },
    { key: 'disabled', label: 'disabled' },
  ];

  @tracked flags = {};
  @tracked checked = false;

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  onChange(event) {
    this.checked = event.target.checked;
  }
}
```
