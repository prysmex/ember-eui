---
order: 14
---

# In a popover

<EuiText>

Always use the compressed version of forms and elements when they exist inside of a popover.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiButtonGroup,
  EuiFieldText,
  EuiFormRow,
  EuiPopover,
  EuiSelect,
} from '@ember-eui/core/components';

export default class CompressedPopoverDemo extends Component {
  selectOptions = [
    { value: 'option_one', text: 'Option one' },
    { value: 'option_two', text: 'Option two' },
    { value: 'option_three', text: 'Option three' },
  ];

  granularityToggleButtons = [
    { id: 'granularityButton1', label: 'Left' },
    { id: 'granularityButton2', label: 'Middle' },
    { id: 'granularityButton3', label: 'Right' },
  ];

  @tracked isPopoverOpen = false;
  @tracked granularityIdSelected = 'granularityButton1';

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  onGranularityChange(optionId) {
    this.granularityIdSelected = optionId;
  }

  <template>
    <EuiPopover @isOpen={{this.isPopoverOpen}} @closePopover={{this.closePopover}}>
      <:button>
        <EuiButton
          @iconType="chevronSingleDown"
          @iconSide="right"
          {{on "click" this.onButtonClick}}
        >
          Open form in popover
        </EuiButton>
      </:button>
      <:content>
        <div style="width: 300px">
          <EuiFormRow @label="Button group" @display="columnCompressed">
            <EuiButtonGroup
              @legend="Granularity of zoom levels"
              @options={{this.granularityToggleButtons}}
              @idSelected={{this.granularityIdSelected}}
              @onChange={{this.onGranularityChange}}
              @buttonSize="compressed"
              @isFullWidth={{true}}
            />
          </EuiFormRow>
          <EuiFormRow @label="Text field" @display="columnCompressed">
            <EuiFieldText name="first" @compressed={{true}} />
          </EuiFormRow>
          <EuiFormRow @label="Select" @display="columnCompressed">
            <EuiSelect @options={{this.selectOptions}} @compressed={{true}} />
          </EuiFormRow>
        </div>
      </:content>
    </EuiPopover>
  </template>
}
```
