---
order: 5
---

# Options can be mixed (indeterminate)

<EuiText>

Setting an option to `checked: 'mixed'` allows showing an indeterminate/mixed state. This state can only be set by the consuming application, and should typically be used to show that another state being controlled by the `EuiSelectable` has some, but not all, of the options selected.

When clicking a mixed option, the option will cycle to "on", and after that cycle between on -> off (if `@allowExclusions` is true) -> undefined). Users cannot manually cycle back to mixed.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiSelectable, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class SelectableMixedDemo extends Component {
  initialOptions = [
    { label: 'Titan', checked: 'mixed' },
    { label: 'Enceladus is disabled', disabled: true },
    { label: 'Mimas', checked: 'on' },
    { label: 'Dione', checked: 'mixed' },
    { label: 'Iapetus' },
    { label: 'Phoebe', checked: 'mixed' },
    { label: 'Rhea' },
    { label: "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology" },
    { label: 'Tethys' },
    { label: 'Hyperion' },
  ];

  @tracked options = this.initialOptions;

  @action
  setOptions(options) {
    this.options = options;
  }

  @action
  reset() {
    this.options = this.initialOptions;
  }

  <template>
    <EuiSelectable
      aria-label="Example of Selectable supporting mixed state"
      @options={{this.options}}
      @onChange={{this.setOptions}}
    />
    <EuiSpacer @size="s" />
    <EuiButton {{on "click" this.reset}}>Reset mixed options</EuiButton>
  </template>
}
```
