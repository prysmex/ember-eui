---
order: 13
---

# Button group tooltips

<EuiText>

Buttons within a button group will automatically display a default browser tooltip containing the button `label` text. This can be customized or unset via the `title` property in your `@options` button configuration.

To instead display an `EuiToolTip` around your button(s), pass the `toolTipContent` property. You can also use `toolTipProps` to customize tooltip placement, title, and any other argument that `EuiToolTip` accepts.

**Beta: showing tooltips on a disabled `EuiButtonGroup`.** If you need disabled buttons to show tooltips, add `@hasAriaDisabled={{true}}` to switch from the native to the custom disabled behavior, which keeps the buttons focusable (see "Disabled and focusable" above).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup, EuiFormRow, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked toggleIdSelected = 'buttonGroup__1';
  @tracked disableButton = false;

  toggleButtons = [
    { id: 'buttonGroup__0', label: 'Default title' },
    {
      id: 'buttonGroup__1',
      label: 'Custom tooltip content',
      toolTipContent: 'This is a custom tooltip'
    },
    {
      id: 'buttonGroup__2',
      label: 'Custom tooltip props',
      toolTipContent: 'This is another custom tooltip',
      toolTipProps: { title: 'My custom title', position: 'right' }
    }
  ];

  @action
  toggleDisabled() {
    this.disableButton = !this.disableButton;
  }

  @action
  onChange(optionId) {
    this.toggleIdSelected = optionId;
  }

  <template>
    <EuiSwitch @compressed={{true}} @label="Disabled" @checked={{this.disableButton}} @onChange={{this.toggleDisabled}} />
    <EuiSpacer />

    <EuiFormRow @label="Default button group with tooltips" @fullWidth={{true}}>
      <EuiButtonGroup
        @legend="This is a group with tooltips"
        @options={{this.toggleButtons}}
        @idSelected={{this.toggleIdSelected}}
        @isDisabled={{this.disableButton}}
        @onChange={{this.onChange}}
      />
    </EuiFormRow>
    <EuiFormRow @label="With custom disabled behavior and tooltips" @fullWidth={{true}}>
      <EuiButtonGroup
        @legend="This is a group with tooltips"
        @options={{this.toggleButtons}}
        @idSelected={{this.toggleIdSelected}}
        @isDisabled={{this.disableButton}}
        @hasAriaDisabled={{true}}
        @onChange={{this.onChange}}
      />
    </EuiFormRow>
  </template>
}
```
