---
order: 2
---

# Disabled

<EuiText>

Set the argument `@isDisabled` to make the combo box disabled.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiComboBox } from '@ember-eui/core/components';

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

export default class ComboBoxDisabledDemo extends Component {
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
      @isDisabled={{true}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
