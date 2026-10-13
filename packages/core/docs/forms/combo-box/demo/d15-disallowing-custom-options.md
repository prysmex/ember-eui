---
order: 15
---

# Disallowing custom options

<EuiText>

Leave out the `@onCreateOption` argument to disallow the creation of custom options. Text that matches no option stays in the input when the combo box loses focus, and marks it invalid; `@onSearchChange` tells you whether any option matches, to explain why.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiComboBox } from '@ember-eui/core/components';

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

export default class ComboBoxNoCustomDemo extends Component {
  options = MOONS;

  @tracked selectedOptions = [MOONS[2], MOONS[4]];
  @tracked error;
  searchValue = '';

  get isInvalid() {
    return this.error !== undefined;
  }

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
    this.error = undefined;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  @action
  onSearchChange(value, hasMatchingOptions) {
    this.searchValue = value;
    this.error =
      value.length === 0 || hasMatchingOptions
        ? undefined
        : `"${value}" is not a valid option`;
  }

  @action
  onBlur() {
    const value = this.searchValue;

    this.error =
      value.length === 0 ? undefined : `"${value}" is not a valid option`;
  }

  <template>
    <EuiFormRow @error={{this.error}} @isInvalid={{this.isInvalid}}>
      <EuiComboBox
        @ariaLabel="Accessible screen reader label"
        @placeholder="Select one or more options"
        @options={{this.options}}
        @selectedOptions={{this.selectedOptions}}
        @searchField="label"
        @onChange={{this.onChange}}
        @removeTag={{this.removeTag}}
        @onSearchChange={{this.onSearchChange}}
        @onBlur={{this.onBlur}}
        @isInvalid={{this.isInvalid}}
        as |option|
      >
        {{option.label}}
      </EuiComboBox>
    </EuiFormRow>
  </template>
}
```
