---
order: 3
---

# Single selection

<EuiText>

Selection can be restricted to a single option at a time with `@singleSelection`. Passing `{{true}}` allows for 0 or 1 option to be selected, while `"always"` requires 1 option to be selected at all times. The default value is `false`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';

export default class SelectableSingleDemo extends Component {
  @tracked options = [
    { label: 'Titan', checked: 'on' },
    { label: 'Enceladus is disabled', disabled: true },
    { label: 'Mimas' },
    { label: 'Dione' },
    { label: 'Iapetus' },
    { label: 'Phoebe' },
    { label: 'Rhea' },
    { label: "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology" },
    { label: 'Tethys' },
    { label: 'Hyperion' },
  ];
  @tracked always = true;

  @action
  setOptions(options) {
    this.options = options;
  }

  @action
  setAlways(event) {
    this.always = event.target.checked;
  }

  get singleSelection() {
    return this.always ? 'always' : true;
  }

  <template>
    <EuiSwitch
      @label="Show as 'always'"
      @checked={{this.always}}
      @onChange={{this.setAlways}}
    />
    <EuiSpacer />
    <EuiSelectable
      aria-label="Single selection example"
      @options={{this.options}}
      @onChange={{this.setOptions}}
      @singleSelection={{this.singleSelection}}
    />
  </template>
}
```
