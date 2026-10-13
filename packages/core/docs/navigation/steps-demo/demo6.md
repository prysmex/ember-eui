---
order: 6
---

# Custom title sizes

<EuiText>

You can set a different title size using `@titleSize` on each **EuiStep**. The title size `xs` will automatically generate smaller steps circles.

The title size `xxs` affects only the size of the accompanying **unnumbered** step indicator, but not the title itself.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup, EuiCode, EuiSpacer, EuiStep, EuiSteps, EuiTitle } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked titleSize = 'm';

  sizeButtons = [
    { id: 'xxs', label: 'XXSmall' },
    { id: 'xs', label: 'XSmall' },
    { id: 's', label: 'Small' },
    { id: 'm', label: 'Medium' }
  ];

  @action
  sizeOnChange(optionId) {
    this.titleSize = optionId;
  }

  <template>
    <EuiTitle @size="xxs" @tagName="h3">Step Size</EuiTitle>
    <EuiSpacer @size="s" />
    <EuiButtonGroup
      @legend="Step size toggle"
      @options={{this.sizeButtons}}
      @idSelected={{this.titleSize}}
      @onChange={{this.sizeOnChange}}
    />
    <EuiSpacer @size="m" />
    <EuiSteps>
      <EuiStep @step={{1}} @title="Step 1" @titleSize={{this.titleSize}}>
        <p>
          Both step title and circle indicators will adjust in size based on the
          <EuiCode>@titleSize</EuiCode> argument
        </p>
      </EuiStep>
      <EuiStep @step={{2}} @title="Step 2" @titleSize={{this.titleSize}}>
        <p>
          Both step title and circle indicators will adjust in size based on the
          <EuiCode>@titleSize</EuiCode> argument
        </p>
      </EuiStep>
    </EuiSteps>
  </template>
}
```
