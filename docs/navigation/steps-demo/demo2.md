# Statuses

```hbs template
<EuiSteps>
  <EuiStep
    @step={{1}}
    @title="Step 1"
  >
    You do this!
  </EuiStep>
  <EuiStep
    @title="Step 2"
    @status={{this.status}}
    @step={{2}}
  >
    You did good! {{if (eq this.status "danger") "(or not)"}}
    <EuiSubSteps>
      Click the buttons below to change status!
      <EuiFlexGroup>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color="danger" @onClick={{this.setDanger}}>
            Set Danger
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color="secondary" @onClick={{this.setComplete}}>
            Set Complete
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color="warning" @onClick={{this.setWarning}}>
            Set Warning
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color="primary" @onClick={{this.setLoading}}>
            Set Loading
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButtonEmpty @onClick={{this.setDisabled}}>
            Set Disabled
          </EuiButtonEmpty>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButtonEmpty @onClick={{this.setIncomplete}}>
            Set Incomplete
          </EuiButtonEmpty>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButtonEmpty @onClick={{this.reset}}>
            Reset
          </EuiButtonEmpty>
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiSubSteps>
  </EuiStep>
</EuiSteps>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoStepsComponent extends Component {
  @tracked status = null;

  @action
  setComplete() {
    this.status = "complete";
  }

  @action
  setDanger() {
    this.status = "danger";
  }

  @action
  setWarning() {
    this.status = "warning";
  }

  @action
  setLoading() {
    this.status = "loading";
  }

  @action
  setDisabled() {
    this.status = "disabled";
  }

  @action
  setIncomplete() {
    this.status = "incomplete";
  }

  @action
  reset() {
    this.status = null;
  }
}
```
