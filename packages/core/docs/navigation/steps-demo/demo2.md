---
order: 4
---

# Statuses

<EuiText>
<p>Steps can optionally include <EuiCode>status</EuiCode> prop that will alter the look of the number prefix. The options are <EuiCode>incomplete</EuiCode>, <EuiCode>complete</EuiCode>, <EuiCode>warning</EuiCode>, <EuiCode>danger</EuiCode>, <EuiCode>disabled</EuiCode> and <EuiCode>loading</EuiCode>. This is used mostly as a final step when you need to make some sort of final check.</p>
</EuiText>

```hbs template
<EuiSteps>
  <EuiStep @step={{1}} @title='Step 1'>
    You do this!
  </EuiStep>
  <EuiStep @title='Step 2' @status={{this.status}} @step={{2}}>
    We are fancy buttons just waiting to be pushed!
    <div>
      <EuiSpacer />
      <EuiFlexGroup>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color='danger' {{on 'click' this.setDanger}}>
            Set Danger
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color='success' {{on 'click' this.setComplete}}>
            Set Complete
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color='warning' {{on 'click' this.setWarning}}>
            Set Warning
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color='primary' {{on 'click' this.setLoading}}>
            Set Loading
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButtonEmpty {{on 'click' this.setDisabled}}>
            Set Disabled
          </EuiButtonEmpty>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButtonEmpty {{on 'click' this.setIncomplete}}>
            Set Incomplete
          </EuiButtonEmpty>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButtonEmpty {{on 'click' this.reset}}>
            Reset
          </EuiButtonEmpty>
        </EuiFlexItem>
      </EuiFlexGroup>
    </div>
  </EuiStep>
</EuiSteps>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoStepsDemo2Component extends Component {
  @tracked status = null;

  @action
  setComplete() {
    this.status = 'complete';
  }

  @action
  setDanger() {
    this.status = 'danger';
  }

  @action
  setWarning() {
    this.status = 'warning';
  }

  @action
  setLoading() {
    this.status = 'loading';
  }

  @action
  setDisabled() {
    this.status = 'disabled';
  }

  @action
  setIncomplete() {
    this.status = 'incomplete';
  }

  @action
  reset() {
    this.status = null;
  }
}
```
