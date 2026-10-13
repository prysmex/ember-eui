---
order: 8
---

# Horizontal steps as data

<EuiText>

**EuiStepsHorizontal** takes upstream's `steps` array too, with `@steps`: each entry has a `title`, a `status` (defaults to `"incomplete"`), `onClick`, `disabled` and `size`; other keys such as `data-test-subj` become attributes of the step's button. Steps are numbered by position. Use `@size` to generate smaller step circles.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup, EuiSpacer, EuiStepsHorizontal, EuiTitle } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked toggleSize = 'm';

  horizontalSteps = [
    { title: 'Completed step 1', status: 'complete', onClick: () => {} },
    { title: 'Selected step 2', status: 'current', onClick: () => {} },
    { title: 'Incomplete step 3 which will wrap to the next line', onClick: () => {} },
    { title: 'Disabled step 4', status: 'disabled', onClick: () => {} }
  ];

  sizeButtons = [
    { id: 'xs', label: 'XSmall' },
    { id: 's', label: 'Small' },
    { id: 'm', label: 'Medium' }
  ];

  @action
  sizeOnChange(optionId) {
    this.toggleSize = optionId;
  }

  <template>
    <EuiTitle @size="xxs" @tagName="h3">Step Size</EuiTitle>
    <EuiSpacer @size="s" />
    <EuiButtonGroup
      @legend="Horizontal step size toggle"
      @options={{this.sizeButtons}}
      @idSelected={{this.toggleSize}}
      @onChange={{this.sizeOnChange}}
    />
    <EuiStepsHorizontal @steps={{this.horizontalSteps}} @size={{this.toggleSize}} />
  </template>
}
```
