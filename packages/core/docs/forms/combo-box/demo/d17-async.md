---
order: 17
---

# Async

<EuiText>

Use `@onSearchChange` to handle searches asynchronously, and `@async` so the options you load are listed as they are. Use `@isLoading` to let the user know that something async is happening. (`@search`, which returns the matches or a promise of them, is shown in Searching a server.)

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
  @tracked options = [];
  @tracked selectedOptions = [];
  @tracked isLoading = false;
  searchTimeout;

  constructor(owner, args) {
    super(owner, args);
    // Simulate initial load.
    this.onSearchChange('');
  }

  willDestroy() {
    super.willDestroy();
    clearTimeout(this.searchTimeout);
  }

  @action
  onSearchChange(searchValue) {
    this.isLoading = true;
    this.options = [];
    clearTimeout(this.searchTimeout);

    this.searchTimeout = setTimeout(() => {
      // Simulate a remotely-executed search.
      this.isLoading = false;
      this.options = this.allOptions.filter((option) =>
        option.label.toLowerCase().includes(searchValue.toLowerCase())
      );
    }, 1200);
  }

  @action
  onCreateOption(searchValue, flattenedOptions = []) {
    const normalizedSearchValue = searchValue.trim().toLowerCase();

    if (!normalizedSearchValue) {
      return;
    }

    const newOption = { label: searchValue };

    // Create the option if it doesn't exist.
    if (
      flattenedOptions.findIndex(
        (option) => option.label.trim().toLowerCase() === normalizedSearchValue
      ) === -1
    ) {
      // Simulate creating this option on the server.
      this.allOptions = [...this.allOptions, newOption];
      this.options = [...this.options, newOption];
    }

    // Select the option.
    this.selectedOptions = [...this.selectedOptions, newOption];
  }

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  <template>
    <EuiComboBox
      @ariaLabel="Accessible screen reader label"
      @placeholder="Search asynchronously"
      @async={{true}}
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @isLoading={{this.isLoading}}
      @onChange={{this.onChange}}
      @onSearchChange={{this.onSearchChange}}
      @onCreateOption={{this.onCreateOption}}
    />
  </template>
}
```
