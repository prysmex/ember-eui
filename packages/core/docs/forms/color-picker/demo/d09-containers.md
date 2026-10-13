---
order: 9
---

# Containers

<EuiText>

Demonstrating that the color picker can exist in portal containers and that its popover positioning works in nested contexts.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiButton, EuiPopover, EuiFormRow, EuiModal, EuiModalBody, EuiModalHeader, EuiModalHeaderTitle, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class ColorPickerContainersDemo extends Component {
  @tracked color = '#FFF';
  @tracked isModalVisible = false;
  @tracked isPopoverOpen = false;

  @action
  setColor(text) {
    this.color = text;
  }

  @action
  closeModal() {
    this.isModalVisible = false;
  }

  @action
  showModal() {
    this.isModalVisible = true;
  }

  @action
  togglePopover() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  <template>
    <EuiFormRow
      @label="Color picker"
      @helpText="This color picker is inside of a form row"
    >
      <EuiColorPicker @color={{this.color}} @onChange={{this.setColor}} />
    </EuiFormRow>
    <EuiSpacer />
    <EuiFormRow @label="Unruly focus management">
      <EuiPopover
        @isOpen={{this.isPopoverOpen}}
        @closePopover={{this.closePopover}}
      >
        <:button>
          <EuiButton
            @iconType="chevronSingleDown"
            @iconSide="right"
            {{on "click" this.togglePopover}}
          >
            Open popover
          </EuiButton>
        </:button>
        <:content>
          <div style="width: 300px">
            <EuiFormRow @label="Color picker">
              <EuiColorPicker @color={{this.color}} @onChange={{this.setColor}} />
            </EuiFormRow>
          </div>
        </:content>
      </EuiPopover>
    </EuiFormRow>
    <EuiSpacer @size="m" />
    <EuiButton {{on "click" this.showModal}}>Show modal</EuiButton>
    {{#if this.isModalVisible}}
      <EuiModal @onClose={{this.closeModal}} style="width: 800px">
        <EuiModalHeader>
          <EuiModalHeaderTitle>Color picker in a modal</EuiModalHeaderTitle>
        </EuiModalHeader>
        <EuiModalBody>
          <EuiFormRow @label="Color picker">
            <EuiColorPicker @color={{this.color}} @onChange={{this.setColor}} />
          </EuiFormRow>
        </EuiModalBody>
      </EuiModal>
    {{/if}}
  </template>
}
```
