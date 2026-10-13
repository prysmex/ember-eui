---
order: 1
---

# Radio group

<EuiText>

Use an `EuiRadioGroup` when you want to generate a group of radio buttons by passing an array of `@options` with an `id` and `label` for each object. Pass a single `@name` to define the group. For more details on which selection component to use, see the selection overview.

When the individual labels for each radio do not provide a sufficient description, pass a `@legend` to the group.

The switches above the group are docs-only helpers that toggle `@compressed` and `@disabled`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiSpacer, EuiRadioGroup } from '@ember-eui/core/components';
import { get, fn } from '@ember/helper';

export default class RadioGroupDemo extends Component {
  toggles = [
    { key: 'compressed', label: 'compressed' },
    { key: 'disabled', label: 'disabled' },
  ];

  radios = [
    {
      id: 'radioGroupItem-first',
      label: 'Option one',
    },
    {
      id: 'radioGroupItem-second',
      label: 'Option two is checked by default',
    },
    {
      id: 'radioGroupItem-third',
      label: 'Option three is disabled',
      disabled: true,
    },
  ];

  @tracked flags = {};
  @tracked radioIdSelected = 'radioGroupItem-second';

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  onChange(optionId) {
    this.radioIdSelected = optionId;
  }

  <template>
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
    <EuiRadioGroup
      @options={{this.radios}}
      @idSelected={{this.radioIdSelected}}
      @onChange={{this.onChange}}
      @name="radio group"
      @legend="This is a legend for a radio group"
      @compressed={{this.flags.compressed}}
      @disabled={{this.flags.disabled}}
    />
  </template>
}
```
