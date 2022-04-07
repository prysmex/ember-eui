---
order: 5
---

# Horizontal Steps

<EuiText>
<p>For use when forms/setup instructions can and should be split into multiple pages. Each step should correspond to an individual page of form elements, using the <EuiCode>status</EuiCode> key to denote the user's progress.</p>
<p>For horizontal steps, the <EuiCode>status</EuiCode> key defaults to <EuiCode>"incomplete"</EuiCode> and the default filled styling is reserved for indicating <EuiCode>"current"</EuiCode> status.</p>
</EuiText>

```hbs template
<EuiStepsHorizontal>
  <EuiStepHorizontal
    @title='Completed step 1'
    @status='complete'
    @step={{1}}
    @isComplete={{true}}
  />
  <EuiStepHorizontal @title='Selected step 2' @step={{2}} @status='current' />
  <EuiStepHorizontal
    @title='Incomplete step 3 which will wrap to the next line'
    @step={{3}}
  />
  <EuiStepHorizontal
    @title='Disabled step 4'
    @status='disabled'
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
