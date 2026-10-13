---
order: 5
---

# Conveying status

<EuiText>

Steps can optionally include a `@status` argument that will alter the look of the number prefix. The options are `incomplete`, `complete`, `warning`, `danger`, `disabled` and `loading`. This is used mostly as a final step when you need to make some sort of final check.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiButton, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiStep, EuiSteps } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked status = 'incomplete';

  @action
  setStatus(status) {
    this.status = status;
  }

  <template>
    <EuiSteps>
      <EuiStep @step={{1}} @title="Normal step">
        <p>Do this first</p>
      </EuiStep>
      <EuiStep
        @step={{2}}
        @title="Push the button to complete this final step"
        @status={{this.status}}
      >
        <p>We are fancy buttons just waiting to be pushed!</p>
        <EuiSpacer />
        <EuiFlexGroup @gutterSize="s" @alignItems="center" @responsive={{false}} @wrap={{true}}>
          <EuiFlexItem @grow={{false}}>
            {{#if (eq this.status "complete")}}
              <EuiButton {{on "click" (fn this.setStatus "incomplete")}}>Reset</EuiButton>
            {{else}}
              <EuiButton {{on "click" (fn this.setStatus "complete")}}>You complete me</EuiButton>
            {{/if}}
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            {{#if (eq this.status "warning")}}
              <EuiButton @color="warning" {{on "click" (fn this.setStatus "incomplete")}}>Reset</EuiButton>
            {{else}}
              <EuiButton @color="warning" {{on "click" (fn this.setStatus "warning")}}>Uh oh!</EuiButton>
            {{/if}}
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            {{#if (eq this.status "danger")}}
              <EuiButton @color="danger" {{on "click" (fn this.setStatus "incomplete")}}>Reset</EuiButton>
            {{else}}
              <EuiButton @color="danger" {{on "click" (fn this.setStatus "danger")}}>Something terrible</EuiButton>
            {{/if}}
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            {{#if (eq this.status "disabled")}}
              <EuiButton @color="accent" {{on "click" (fn this.setStatus "incomplete")}}>Reset</EuiButton>
            {{else}}
              <EuiButton @color="accent" {{on "click" (fn this.setStatus "disabled")}}>Disabled</EuiButton>
            {{/if}}
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiStep>
    </EuiSteps>
  </template>
}
```
