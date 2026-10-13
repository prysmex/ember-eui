---
order: 12
---

# Custom option matcher

<EuiText>

When searching for options, `EuiSelectable` uses a partial equality string matcher by default, displaying all options whose labels include the searched string.

In rare cases, you may want to customize this behavior. You can do so by passing a custom option matcher function to the `@optionMatcher` argument. The function gets `{ option, searchValue, normalizedSearchValue }` (the type is `EuiSelectableOptionMatcher`) and must return `true` for options that should be visible for the given search string.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable } from '@ember-eui/core/components';

export default class SelectableOptionMatcherDemo extends Component {
  @tracked options = [
    { label: 'Titan', 'data-test-subj': 'titanOption' },
    { label: 'Enceladus is disabled', disabled: true },
    { label: 'Mimas', checked: 'on' },
    { label: 'Dione' },
    { label: 'Iapetus', checked: 'on' },
    { label: 'Phoebe' },
    { label: 'Rhea' },
    { label: "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology" },
    { label: 'Tethys' },
    { label: 'Hyperion' },
  ];

  searchProps = { 'data-test-subj': 'selectableSearchHere' };

  startsWithMatcher = ({ option, searchValue }) => option.label.startsWith(searchValue);

  @action
  setOptions(options) {
    this.options = options;
  }

  <template>
    <EuiSelectable
      aria-label="Searchable example"
      @searchable={{true}}
      @searchProps={{this.searchProps}}
      @options={{this.options}}
      @onChange={{this.setOptions}}
      @optionMatcher={{this.startsWithMatcher}}
    />
  </template>
}
```
