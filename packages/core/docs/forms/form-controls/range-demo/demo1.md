---
order: 1
---

# Demo

```hbs template
<EuiRange
  @min={{100}}
  @max={{200}}
  @step={{0.5}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  aria-label="An example of EuiRange with showLabels prop"
/>
<EuiSpacer @size="xl" />
<EuiRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  aria-label="An example of EuiRange with showValue prop"
/>
<EuiSpacer @size="xl" />
<EuiRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  @showRange={{true}}
  @valuePrepend="100 -"
  aria-label="An example of EuiRange with valuePrepend prop"
>
  <:min as |minVal|>
    The min value is: {{minVal}}
  </:min>
  <:valueAppend>
    🚀
  </:valueAppend>
</EuiRange>
<EuiSpacer @size="xl" />
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked value = 170;
  @action
  onChange(e) {
    this.value = e.target.value;
  }
}
```
