---
order: 15
---

# Duplicate labels

<EuiText>

In general, it is not recommended to use duplicate labels on the options because the user has no way to distinguish between them. If you need duplicate labels, make sure each option is a distinct object, and keep the selection by reference (as `@onChange` returns the same option objects).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiComboBox } from '@ember-eui/core/components';

const MOONS = [
  { label: 'Titan', key: 'titan1' },
  { label: 'Titan', key: 'titan2' },
  { label: 'Enceladus is disabled', disabled: true },
  { label: 'Titan', key: 'titan3' },
  { label: 'Dione' },
];

export default class ComboBoxDuplicateLabelsDemo extends Component {
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
      @placeholder="Select or create options"
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @onCreateOption={{this.onCreateOption}}
      @isClearable={{true}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
