---
order: 4
---

# Containers

<EuiText>

This example demonstrates how the combo box works within containers. The options list renders in a portal, so it is important that it works within other portal-using components such as popovers, modals and flyouts.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiComboBox, EuiSpacer, EuiPopover, EuiButton, EuiModal, EuiModalHeader, EuiModalHeaderTitle, EuiModalBody } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

const MOONS = [
  { label: 'Titan' },
  { label: 'Enceladus' },
  { label: 'Mimas' },
  { label: 'Dione' },
  { label: 'Iapetus' },
  { label: 'Phoebe' },
  { label: 'Rhea' },
  {
    label:
      "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology",
  },
  { label: 'Tethys' },
  { label: 'Hyperion' },
];

export default class ComboBoxContainersDemo extends Component {
  @tracked isModalVisible = false;
  @tracked isPopoverOpen = false;

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

  @tracked options = MOONS;
  @tracked selectedOptions = [MOONS[2], MOONS[4]];

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  @action
  onCreateOption(searchValue) {
    const normalizedSearchValue = searchValue.trim().toLowerCase();

    if (!normalizedSearchValue) {
      return;
    }

    const newOption = { label: searchValue };

    // Create the option if it doesn't exist.
    if (
      !this.options.some(
        (option) => option.label.trim().toLowerCase() === normalizedSearchValue
      )
    ) {
      this.options = [...this.options, newOption];
    }

    // Select the option.
    this.selectedOptions = [...this.selectedOptions, newOption];
  }

  <template>
    <EuiFormRow
      @label="Combo box"
      @helpText="This combo box is inside of a form row"
    >
      <EuiComboBox
        @ariaLabel="Combo box in a form row"
        @placeholder="Select or create options"
        @options={{this.options}}
        @selectedOptions={{this.selectedOptions}}
        @searchField="label"
        @onChange={{this.onChange}}
        @removeTag={{this.removeTag}}
        @onCreateOption={{this.onCreateOption}}
        as |option|
      >
        {{option.label}}
      </EuiComboBox>
    </EuiFormRow>
    <EuiSpacer />
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
          <EuiComboBox
            @ariaLabel="Combo box in a popover"
            @placeholder="Select or create options"
            @options={{this.options}}
            @selectedOptions={{this.selectedOptions}}
            @searchField="label"
            @onChange={{this.onChange}}
            @removeTag={{this.removeTag}}
            @onCreateOption={{this.onCreateOption}}
            as |option|
          >
            {{option.label}}
          </EuiComboBox>
        </div>
      </:content>
    </EuiPopover>
    <EuiSpacer @size="m" />
    <EuiButton {{on "click" this.showModal}}>Show modal</EuiButton>
    {{#if this.isModalVisible}}
      <EuiModal @onClose={{this.closeModal}} style="width: 800px">
        <EuiModalHeader>
          <EuiModalHeaderTitle>Combo box in a modal</EuiModalHeaderTitle>
        </EuiModalHeader>
        <EuiModalBody>
          <EuiComboBox
            @ariaLabel="Combo box in a modal"
            @placeholder="Select or create options"
            @options={{this.options}}
            @selectedOptions={{this.selectedOptions}}
            @searchField="label"
            @onChange={{this.onChange}}
            @removeTag={{this.removeTag}}
            @onCreateOption={{this.onCreateOption}}
            as |option|
          >
            {{option.label}}
          </EuiComboBox>
        </EuiModalBody>
      </EuiModal>
    {{/if}}
  </template>
}
```
