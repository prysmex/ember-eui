---
order: 18
---

# With delimiter

<EuiText>

Pass a unique character to the `@delimiter` argument to aid in option creation. This is best used when knowing that content may be pasted from elsewhere such as a comma separated list.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiComboBox } from '@ember-eui/core/components';

const staticOptions = [
  { label: 'Titan', 'data-test-subj': 'titanOption' },
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

export default class ComboBoxDelimiterDemo extends Component {
  @tracked options = staticOptions;
  @tracked selectedOptions = [staticOptions[2], staticOptions[4]];

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  @action
  onCreateOption(searchValue, flattenedOptions = []) {
    const normalizedSearchValue = searchValue.trim().toLowerCase();

    if (!normalizedSearchValue) {
      return;
    }

    const newOption = {
      label: searchValue,
    };

    // Create the option if it doesn't exist.
    if (
      flattenedOptions.findIndex(
        (option) => option.label.trim().toLowerCase() === normalizedSearchValue
      ) === -1
    ) {
      this.options = [...this.options, newOption];
    }

    // Select the option. Reading `this.selectedOptions` again keeps the
    // options added before it, when a pasted list adds several in a row
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
      @delimiter=","
    />
  </template>
}
```
