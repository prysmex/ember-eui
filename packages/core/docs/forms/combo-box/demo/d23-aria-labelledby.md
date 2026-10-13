---
order: 23
---

# Accessible label with aria-labelledby

<EuiText>

Sometimes it's preferable to label a combo box with a heading or paragraph. Give a text element an `id`, then pass it to `@ariaLabelledBy`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiText, EuiSpacer, EuiComboBox } from '@ember-eui/core/components';

const MOONS = [
  { label: 'Titan' },
  { label: 'Enceladus' },
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

export default class ComboBoxAriaLabelledByDemo extends Component {
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
    <EuiText>
      <h3 id="combo-box-generated-heading">Heading as a label</h3>
    </EuiText>
    <EuiSpacer @size="s" />
    <EuiComboBox
      @ariaLabelledBy="combo-box-generated-heading"
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
