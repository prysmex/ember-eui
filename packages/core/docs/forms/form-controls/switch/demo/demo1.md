---
order: 1
---

```hbs template
<EuiForm>
  <EuiSwitch
    @id='131'
    @label='I am a checkbox'
    @checked={{this.switch1}}
    @onChange={{pick 'target.checked' (set this 'switch1')}}
  />
  <EuiSpacer />
  <EuiSwitch
    @id='131d'
    @checked={{this.switch2}}
    @onChange={{pick 'target.checked' (set this 'switch2')}}
  >
    <:label>
      Switch with custom Label
    </:label>
  </EuiSwitch>
  <EuiSpacer />
  <EuiSwitch
    @disabled={{true}}
    @id='disabled-checkbox'
    @label='Disabled switch'
    @checked={{this.radio1}}
  />
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked switch1 = false;
  @tracked switch2 = false;
}
```
