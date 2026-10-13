---
order: 2
---

# Horizontal Steps

<EuiText>

**EuiStepsHorizontal** should be used when forms/setup instructions can and should be split into multiple pages. Each step should correspond to an individual page of form elements, using the `@status` argument to denote the user's progress.

For horizontal steps, the `@status` argument defaults to `"incomplete"` and the default filled styling is reserved for indicating `"current"` status.

Use the `@size` argument to generate smaller step circles.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup, EuiSpacer, EuiStepHorizontal, EuiStepsHorizontal, EuiTitle } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked toggleSize = 'm';

  sizeButtons = [
    { id: 'xs', label: 'XSmall' },
    { id: 's', label: 'Small' },
    { id: 'm', label: 'Medium' }
  ];

  @action
  sizeOnChange(optionId) {
    this.toggleSize = optionId;
  }

  @action
  noop() {}

  <template>
    <EuiTitle @size="xxs" @tagName="h3">Step Size</EuiTitle>
    <EuiSpacer @size="s" />
    <EuiButtonGroup
      @legend="Horizontal step size toggle"
      @options={{this.sizeButtons}}
      @idSelected={{this.toggleSize}}
      @onChange={{this.sizeOnChange}}
    />
    <EuiStepsHorizontal @size={{this.toggleSize}}>
      <EuiStepHorizontal
        @title="Completed step 1"
        @step={{1}}
        @status="complete"
        @onStepClick={{this.noop}}
      />
      <EuiStepHorizontal
        @title="Selected step 2"
        @step={{2}}
        @status="current"
        @onStepClick={{this.noop}}
      />
      <EuiStepHorizontal
        @title="Incomplete step 3 which will wrap to the next line"
        @step={{3}}
        @onStepClick={{this.noop}}
      />
      <EuiStepHorizontal
        @title="Disabled step 4"
        @step={{4}}
        @status="disabled"
        @onStepClick={{this.noop}}
      />
    </EuiStepsHorizontal>
  </template>
}
```
