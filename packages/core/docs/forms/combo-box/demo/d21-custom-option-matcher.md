---
order: 21
---

# Custom option matcher

<EuiText>

When searching for options, `EuiComboBox` uses a partial equality string matcher by default, displaying all options whose labels include the searched string and taking the `@isCaseSensitive` argument into account.

In rare cases, you may want to customize this behavior. You can do so by passing a custom option matcher function to the `@optionMatcher` argument. It receives `{ option, searchValue, normalizedSearchValue, isCaseSensitive }` and returns `true` for options that should be visible for the given search string. (ember-power-select's `@matcher`, `(option, searchText) => -1` for no match, works too.)

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

export default class ComboBoxMatcherDemo extends Component {
  options = MOONS;

  @tracked selectedOptions = [];

  startsWithMatcher = ({ option, searchValue }) =>
    option.label.startsWith(searchValue);

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
      @placeholder="Select options"
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @isClearable={{true}}
      @optionMatcher={{this.startsWithMatcher}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
