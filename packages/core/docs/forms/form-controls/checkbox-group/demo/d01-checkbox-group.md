---
order: 1
---

# Checkbox group

<EuiText>

Use an `EuiCheckboxGroup` when you want to generate a group of checkboxes by passing an array of `@options` with an `id` and `label` for each object. Use the `@idToSelectedMap` to indicate the IDs of the selected items. For more details on which selection component to use, see the selection overview.

When the individual labels for each checkbox do not provide a sufficient description, pass a `@legend` to the group.

Use the `@compressed` argument to tighten up the spacing between checkbox rows.

The switches above the group are docs-only helpers that toggle `@compressed` and `@disabled`.

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
<EuiCheckboxGroup
  @options={{this.checkboxes}}
  @idToSelectedMap={{this.checkboxIdToSelectedMap}}
  @compressed={{this.flags.compressed}}
  @disabled={{this.flags.disabled}}
  @onChange={{this.onChange}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CheckboxGroupDemo extends Component {
  toggles = [
    { key: 'compressed', label: 'compressed' },
    { key: 'disabled', label: 'disabled' },
  ];

  checkboxes = [
    {
      id: 'checkboxGroupItem-first',
      label: 'Option one',
    },
    {
      id: 'checkboxGroupItem-second',
      label: 'Option two is checked by default',
    },
    {
      id: 'checkboxGroupItem-third',
      label: 'Option three is disabled',
      disabled: true,
    },
  ];

  @tracked flags = {};
  @tracked checkboxIdToSelectedMap = { 'checkboxGroupItem-second': true };

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  onChange(optionId) {
    this.checkboxIdToSelectedMap = {
      ...this.checkboxIdToSelectedMap,
      [optionId]: !this.checkboxIdToSelectedMap[optionId],
    };
  }
}
```
