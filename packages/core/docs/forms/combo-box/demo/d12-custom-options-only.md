---
order: 12
---

# Custom options only, with validation

<EuiText>

Alternatively, provide no `@options` to _only_ allow the creation of custom options. Return `false` from `@onCreateOption` to explicitly reject the user's input.

**Ember EUI difference:** the options list still opens to offer the "Add ... as custom option" row; upstream's `noSuggestions` hides the list entirely.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiComboBox } from '@ember-eui/core/components';

// Only allow letters. No spaces, numbers, or special characters.
const isValid = (value) => value.match(/^[a-zA-Z]+$/) !== null;

export default class ComboBoxCustomOnlyDemo extends Component {
  options = [];

  @tracked selectedOptions = [];
  @tracked isInvalid = false;

  @action
  onCreateOption(searchValue) {
    if (!isValid(searchValue)) {
      // Return false to explicitly reject the user's input.
      return false;
    }

    // Select the option.
    this.selectedOptions = [...this.selectedOptions, { label: searchValue }];
  }

  @action
  onInput(searchValue) {
    this.isInvalid = searchValue ? !isValid(searchValue) : false;
  }

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
    this.isInvalid = false;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  <template>
    <EuiFormRow
      @label="Only custom options"
      @isInvalid={{this.isInvalid}}
      @error={{if this.isInvalid "Only letters are allowed"}}
    >
      <EuiComboBox
        @placeholder="Create some tags (letters only)"
        @options={{this.options}}
        @selectedOptions={{this.selectedOptions}}
        @searchField="label"
        @onChange={{this.onChange}}
        @removeTag={{this.removeTag}}
        @onCreateOption={{this.onCreateOption}}
        @onInput={{this.onInput}}
        @isInvalid={{this.isInvalid}}
        as |option|
      >
        {{option.label}}
      </EuiComboBox>
    </EuiFormRow>
  </template>
}
```
