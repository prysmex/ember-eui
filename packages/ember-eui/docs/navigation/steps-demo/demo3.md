---
order: 3
---

# Horizontal Steps

```hbs template
<EuiStepsHorizontal>
  <EuiStepHorizontal
    @title="Cart"
    @step={{1}}
    @isComplete={{true}}
  />
  <EuiStepHorizontal
    @title="Shipping"
    @step={{2}}
    @isComplete={{true}}
  />
  <EuiStepHorizontal
    @title="Payment Method"
    @step={{3}}
    @isSelected={{true}}
  />
  <EuiStepHorizontal
    @title="Review Order"
    @step={{4}}
    @disabled={{true}}
  />
</EuiStepsHorizontal>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoStepsDemo3Component extends Component {
  @tracked isComplete = null;

  @action
  completeStep() {
    this.isComplete = true;
  }
}
```
