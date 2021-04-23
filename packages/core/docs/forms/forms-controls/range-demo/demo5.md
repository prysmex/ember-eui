---
order: 5
---

# Demo

```hbs template
<EuiTitle>
  Levels
</EuiTitle>
<EuiText>
  <p>
    To create colored indicators for certain intervals, pass an array of objects that include a min, max and color. Color options are [ "primary", "success", "warning", "danger" ].
  </p>
  <p>
    Be sure to then add an aria-describedby and match it to the id of a EuiFormHelpText.
  </p>
</EuiText>
<EuiRange
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showTicks={{true}}
  @tickInterval={{20}}
  @levels={{this.levels}}
  aria-label="An example of EuiRange with levels prop"
  aria-describedby="levelsHelp2"
/>
<EuiFormHelpText id="levelsHelp2">
  Recommended levels are {levels[1].min} and above.
</EuiFormHelpText>
<EuiSpacer size="xl" />
<EuiDualRange
  @value={{this.dualValue}}
  @onChange={{set this "dualValue"}}
  @showTicks={{true}}
  @showInput={{true}}
  @ticks={{array (hash label="20kb" value=20) (hash label="100kb" value=100)}}
  @levels={{this.levels}}
  aria-label="An example of EuiDualRange with levels prop"
  aria-describedby="levelsHelp3"
/>
<EuiFormHelpText id="levelsHelp3">
  Recommended size is {levels[1].min}kb and above.
</EuiFormHelpText>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked value = '20';
  @tracked dualValue = [20, 100];

  @action
  onChange(e) {
    this.value = e.target.value;
  }

  levels = [
    {
      min: 0,
      max: 20,
      color: 'danger',
    },
    {
      min: 20,
      max: 100,
      color: 'success',
    },
  ];
}
```
