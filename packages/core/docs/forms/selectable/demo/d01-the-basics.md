---
order: 1
---

# The basics

<EuiText>

`EuiSelectable` aims to make the pattern of a selectable list (with or without search) consistent across implementations. It is the same concept used in `EuiComboBox` and `EuiFilterGroup`.

For more details on which selection component to use, see the selection overview.

**It's not intended for primary navigation**, but can be used to simplify the construction of popover navigational menus; i.e. the spaces menu in the header.

At its simplest, `EuiSelectable` requires an array of `@options` and an `@onChange` action which passes back the altered options array. Without a block, it renders the list (and the search, when `@searchable`).

**Selected options are based on the `checked = 'on'` property.** `EuiSelectable` offers the ability to _exclude_ selections or include selections for some (mixed). Therefore, the `checked` property is one of `undefined | 'on' | 'off' | 'mixed'`. `'on'` is the default for selected options when `@allowExclusions` is false.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable } from '@ember-eui/core/components';

export default class SelectableBasicsDemo extends Component {
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
      aria-label="Basic example"
      @options={{this.options}}
      @onChange={{this.setOptions}}
    />
  </template>
}
```
