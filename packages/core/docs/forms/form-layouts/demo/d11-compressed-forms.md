---
order: 11
---

# Compressed forms

<EuiText>

Also known as **editor-style controls**, compressed forms and controls were specifically created for use when space is at a premium. They are not intended for use when the form is the main objective of the page. They work best in editor-style applications where form controls are being used to create or edit content on the page.

**Do not use compressed and non-compressed form controls in the same form.**

To use compressed forms, pass `@compressed={{true}}` to all form controls.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiCheckboxGroup,
  EuiComboBox,
  EuiFieldText,
  EuiFilePicker,
  EuiFormRow,
  EuiPanel,
  EuiRange,
  EuiSelect,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class CompressedFormDemo extends Component {
  selectOptions = [
    { value: 'option_one', text: 'Option one' },
    { value: 'option_two', text: 'Option two' },
    { value: 'option_three', text: 'Option three' },
  ];

  comboBoxOptions = [
    { label: 'Option one' },
    { label: 'Option two' },
    { label: 'Option three' },
  ];

  checkboxes = [
    { id: 'compressedFormCheckbox-first', label: 'Option one' },
    { id: 'compressedFormCheckbox-second', label: 'Option two is checked by default' },
    { id: 'compressedFormCheckbox-third', label: 'Option three' },
  ];

  @tracked isSwitchChecked = false;
  @tracked checkboxIdToSelectedMap = { 'compressedFormCheckbox-second': true };
  @tracked comboBoxSelectionOptions = [];
  @tracked value = 20;

  @action
  onRangeChange(event) {
    this.value = event.target.value;
  }

  @action
  onSwitchChange() {
    this.isSwitchChecked = !this.isSwitchChecked;
  }

  @action
  onCheckboxChange(optionId) {
    this.checkboxIdToSelectedMap = {
      ...this.checkboxIdToSelectedMap,
      [optionId]: !this.checkboxIdToSelectedMap[optionId],
    };
  }

  @action
  onComboBoxChange(options) {
    this.comboBoxSelectionOptions = options;
  }

  @action
  removeTag(option) {
    this.comboBoxSelectionOptions = this.comboBoxSelectionOptions.filter((o) => o !== option);
  }

  <template>
    <EuiPanel style="max-width: 300px">
      <EuiFormRow @label="Text field" @helpText="I am some friendly help text.">
        <EuiFieldText name="first" @isLoading={{true}} @compressed={{true}} />
      </EuiFormRow>

      <EuiFormRow @label="Select">
        <EuiSelect @options={{this.selectOptions}} @compressed={{true}} />
      </EuiFormRow>

      <EuiFormRow @label="File picker">
        <EuiFilePicker @compressed={{true}} @display="default" />
      </EuiFormRow>

      <EuiFormRow @label="Combobox">
        <EuiComboBox
          @options={{this.comboBoxOptions}}
          @compressed={{true}}
          @searchField="label"
          @selectedOptions={{this.comboBoxSelectionOptions}}
          @onChange={{this.onComboBoxChange}}
          @removeTag={{this.removeTag}}
          as |option|
        >
          {{option.label}}
        </EuiComboBox>
      </EuiFormRow>

      <EuiFormRow @label="Range">
        <EuiRange
          name="range"
          @min={{0}}
          @max={{100}}
          @showInput={{true}}
          @compressed={{true}}
          @value={{this.value}}
          @onChange={{this.onRangeChange}}
        />
      </EuiFormRow>

      <EuiFormRow @label="Switch" @hasChildLabel={{false}}>
        <EuiSwitch
          name="switch"
          @label="Setting name"
          @checked={{this.isSwitchChecked}}
          @onChange={{this.onSwitchChange}}
          @compressed={{true}}
        />
      </EuiFormRow>

      <EuiSpacer @size="m" />

      <EuiCheckboxGroup
        @options={{this.checkboxes}}
        @idToSelectedMap={{this.checkboxIdToSelectedMap}}
        @onChange={{this.onCheckboxChange}}
        @legend="Checkboxes"
        @compressed={{true}}
      />
    </EuiPanel>
  </template>
}
```
