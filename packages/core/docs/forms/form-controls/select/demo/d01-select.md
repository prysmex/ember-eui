---
order: 1
---

# Basic select

<EuiText>

`EuiSelect` is a simple dropdown component that allows users to select a single option from a list. It renders a native HTML `<select>` element.

Use it to allow users to choose from a list of 7 to 12 options. When there are fewer than 7 options consider using an `EuiRadioGroup`. Options are `{ value, text }`; update `@value` from `event.target.value` (always a string) on `change`.

The switches above the field are docs-only helpers that toggle its display arguments.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiSpacer, EuiSelect } from '@ember-eui/core/components';
import { get, fn } from '@ember/helper';
import { on } from '@ember/modifier';

export default class SelectDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'disabled', label: 'disabled' },
  ];

  options = [
    { value: 'option_one', text: 'Option one' },
    { value: 'option_two', text: 'Option two' },
    { value: 'option_three', text: 'Option three' },
  ];

  @tracked flags = {};
  @tracked value = 'option_two';

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  onChange(event) {
    this.value = event.target.value;
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
    <EuiSelect
      @options={{this.options}}
      @value={{this.value}}
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @disabled={{this.flags.disabled}}
      aria-label="Use aria labels when no actual label is in use"
      {{on "change" this.onChange}}
    />
  </template>
}
```
