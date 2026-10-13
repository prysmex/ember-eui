---
order: 2
---

# Searchable

<EuiText>

To add a search component to the list, simply add `@searchable`. You can optionally pass in a `@searchProps` object, which configures the actual `EuiFieldSearch` used (`placeholder`, `compressed`, `isLoading`, `value`, `defaultValue`, `data-test-subj`, `fullWidth`, `incremental`, `disabled`, `readOnly`, `isInvalid`, `id`, and the `onChange`, `onKeyDown`, `onClick`, `onFocus` and `onBlur` handlers); any other key, such as `name`, becomes an attribute of the input. `onChange` (and its Ember alias `onSearch`) returns a second parameter, enabling you to access the list of filtered items. Attributes such as `aria-label` go on the yielded `parts.search`.

**Tip:** the search is performed as a string match against the `option.label` unless a separate `option.searchableLabel` is provided.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable } from '@ember-eui/core/components';

export default class SelectableSearchableDemo extends Component {
  searchProps = { 'data-test-subj': 'selectableSearchHere' };

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
      as |parts|
    >
      <parts.search aria-label="Filter options" />
      <parts.list />
    </EuiSelectable>
  </template>
}
```
