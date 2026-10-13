---
order: 10
---

# Single selection with custom options

<EuiText>

You can allow the user to select a single option and also allow the creation of custom options. To do that, use `@singleSelection` in conjunction with `@onCreateOption`.

**Note:** Creating custom options might not be obvious to the user, so provide help text explaining that this option is available. You can also customize the custom option text by passing a text to `@customOptionText`; `{searchText}` is replaced by what the user typed.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiComboBox } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

const OPTIONS = [
  { label: 'Software Developer' },
  { label: 'Mobile Developer' },
  { label: 'Javascript Engineer' },
  { label: 'UX Designer' },
  { label: 'UI Designer' },
  { label: 'Product Designer' },
  { label: 'QA Engineer' },
];

export default class ComboBoxSingleCustomDemo extends Component {
  options = OPTIONS;

  @tracked selectedOptions = [OPTIONS[2]];

  @action
  onChange(selectedOptions) {
    // We should only get back either 0 or 1 options.
    this.selectedOptions = selectedOptions;
  }

  @action
  onCreateOption(searchValue) {
    const normalizedSearchValue = searchValue.trim().toLowerCase();

    if (!normalizedSearchValue) {
      return;
    }

    // Select the option.
    this.selectedOptions = [{ label: searchValue }];
  }

  <template>
    <EuiFormRow
      @label="Your occupation"
      @helpText="Select an occupation from the list. If your occupation isn't available, create a custom one."
    >
      <EuiComboBox
        @ariaLabel="Accessible screen reader label"
        @placeholder="Select a single option"
        @singleSelection={{hash asPlainText=true}}
        @options={{this.options}}
        @selectedOptions={{this.selectedOptions}}
        @searchField="label"
        @onChange={{this.onChange}}
        @onCreateOption={{this.onCreateOption}}
        @customOptionText="Add {searchText} as your occupation"
        as |option|
      >
        {{option.label}}
      </EuiComboBox>
    </EuiFormRow>
  </template>
}
```
