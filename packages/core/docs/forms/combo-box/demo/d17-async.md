---
order: 17
---

# Async

<EuiText>

Use `@search` to handle searches asynchronously: it receives the typed text and returns the matching options, or a promise of them. Use `@isLoading` to let the user know that something async is happening.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiComboBox } from '@ember-eui/core/components';

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

export default class ComboBoxAsyncDemo extends Component {
  @tracked allOptions = MOONS;
  @tracked selectedOptions = [];

  // Simulate a remotely-executed search.
  @action
  onSearch(searchValue) {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(
          this.allOptions.filter((option) =>
            option.label.toLowerCase().includes(searchValue.toLowerCase())
          )
        );
      }, 1200);
    });
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
      !this.allOptions.some(
        (option) => option.label.trim().toLowerCase() === normalizedSearchValue
      )
    ) {
      // Simulate creating this option on the server.
      this.allOptions = [...this.allOptions, newOption];
    }

    // Select the option.
    this.selectedOptions = [...this.selectedOptions, newOption];
  }

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  <template>
    <EuiComboBox
      @ariaLabel="Accessible screen reader label"
      @placeholder="Search asynchronously"
      @search={{this.onSearch}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @onCreateOption={{this.onCreateOption}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
