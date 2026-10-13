---
order: 2
---

# Searchable

<EuiText>

To add a search component to the list, simply add `@searchable`. You can optionally pass in a `@searchProps` object, which configures the actual `EuiFieldSearch` used (`placeholder`, `compressed`, `defaultValue`). In this example, `onSearch` returns a second parameter, enabling you to access the list of filtered items.

The search is performed as a string match against the `option.label`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

export default class SelectableSearchableDemo extends Component {
  @tracked options = [
    { label: 'Titan' },
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
      @searchProps={{hash placeholder="Filter options"}}
      @options={{this.options}}
      @onChange={{this.setOptions}}
    />
  </template>
}
```
