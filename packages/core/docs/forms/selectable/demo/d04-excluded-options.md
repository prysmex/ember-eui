---
order: 4
---

# Options can be excluded

<EuiText>

Adding `@allowExclusions` allows cycling through the checked options (on -> off -> undefined).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable } from '@ember-eui/core/components';

export default class SelectableExclusionsDemo extends Component {
  @tracked options = [
    { label: 'Titan' },
    { label: 'Enceladus is disabled', disabled: true },
    { label: 'Mimas', checked: 'on' },
    { label: 'Dione', checked: 'off' },
    { label: 'Iapetus', checked: 'off' },
    { label: 'Phoebe', checked: 'on' },
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
      aria-label="Example of Selectable supporting exclusions"
      @allowExclusions={{true}}
      @options={{this.options}}
      @onChange={{this.setOptions}}
    />
  </template>
}
```
