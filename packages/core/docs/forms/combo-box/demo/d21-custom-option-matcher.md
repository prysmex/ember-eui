---
order: 14
---

# Custom option matcher

<EuiText>

When searching for options, `EuiComboBox` uses a partial equality string matcher by default, displaying all options whose labels include the searched string.

In rare cases, you may want to customize this behavior. You can do so by passing a custom matcher function to `@matcher`. It is called with the option and the search text, and returns `-1` for options that should not be visible for the given search string.

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

  startsWithMatcher = (option, searchValue) =>
    option.label.startsWith(searchValue) ? 0 : -1;

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
      @matcher={{this.startsWithMatcher}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
