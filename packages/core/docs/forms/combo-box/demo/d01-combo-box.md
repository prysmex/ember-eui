---
order: 1
---

# Combo box

<EuiText>

`EuiComboBox` lets users select one or more options. It supports searching from a list and creating custom values. It displays a text input with a dropdown of options.

Use `EuiComboBox` when:

- there are many options and users need to search,
- users need to select multiple options, or
- users should be able to add their own custom value.

For more details on which selection component to use, see the selection overview.

The switches above the combo box are docs-only helpers that toggle its display arguments. Pills are removable only when you pass `@removeTag`, which is called with the removed option.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiSpacer, EuiComboBox } from '@ember-eui/core/components';
import { get, fn } from '@ember/helper';

const MOONS = [
  { label: 'Titan' },
  { label: 'Enceladus is disabled', disabled: true },
  { label: 'Mimas' },
  { label: 'Dione' },
  { label: 'Iapetus' },
  { label: 'Phoebe' },
  { label: 'Rhea' },
  {
    label:
      "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology",
  },
  { label: 'Tethys' },
  { label: 'Hyperion' },
];

export default class ComboBoxDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'isDisabled', label: 'isDisabled' },
  ];

  @tracked flags = {};

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @tracked options = MOONS;
  @tracked selectedOptions = [MOONS[2], MOONS[4]];

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  @action
  onCreateOption(searchValue) {
    const normalizedSearchValue = searchValue.trim().toLowerCase();

    if (!normalizedSearchValue) {
      return;
    }

    const newOption = { label: searchValue };

    // Create the option if it doesn't exist.
    if (
      !this.options.some(
        (option) => option.label.trim().toLowerCase() === normalizedSearchValue
      )
    ) {
      this.options = [...this.options, newOption];
    }

    // Select the option.
    this.selectedOptions = [...this.selectedOptions, newOption];
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
    <EuiComboBox
      @ariaLabel="Accessible screen reader label"
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @placeholder="Select or create options"
      @onCreateOption={{this.onCreateOption}}
      @isClearable={{true}}
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @isDisabled={{this.flags.isDisabled}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
