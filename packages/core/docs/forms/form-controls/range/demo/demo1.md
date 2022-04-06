---
order: 1
---

# Single range

<EuiText>
  <h3>Required</h3>
  <ul>
    <li>
      <EuiCode>@min, @max</EuiCode>: Sets the range values.
    </li>
    <li>
      <EuiCode>@step</EuiCode>: Technically not required because the
      default is <EuiCode>1</EuiCode>.
    </li>
    <li>
      <EuiCode>@value, @onChange</EuiCode>
    </li>
  </ul>
  <h3>Optional</h3>
  <ul>
    <li>
      <EuiCode>@showLabels</EuiCode>: While currently considered
      optional, the property should be added to explicitly state the
      range to the user.
    </li>
    <li>
      <EuiCode>@showValue</EuiCode>: Displays a tooltip style indicator
      of the selected value. You can add <EuiCode>:valuePrepend</EuiCode>
      and/or <EuiCode>:valueAppend</EuiCode> blocks to bookend the value with
      custom content.
    </li>
    <li>
      <EuiCode>@showRange</EuiCode>: Displays a thickened line from the
      minimum value to the selected value.
    </li>
  </ul>
</EuiText>

```hbs template
<EuiRange
  @min={{100}}
  @max={{200}}
  @step={{0.5}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  aria-label='An example of EuiRange with showLabels prop'
/>
<EuiSpacer @size='xl' />
<EuiRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  aria-label='An example of EuiRange with showValue prop'
/>
<EuiSpacer @size='xl' />
<EuiRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  @showRange={{true}}
  @valuePrepend='100 -'
  aria-label='An example of EuiRange with valuePrepend prop'
>
  <:min as |minVal|>
    The min value is:
    {{minVal}}
  </:min>
  <:valueAppend>
    🚀
  </:valueAppend>
</EuiRange>
<EuiSpacer @size='xl' />
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked value = 170;
  @action
  onChange(e) {
    this.value = e.target.value;
  }
}
```
