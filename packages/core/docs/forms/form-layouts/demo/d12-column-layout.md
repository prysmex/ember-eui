---
order: 12
---

# Column layout

<EuiText>

Editor-style controls can be displayed in a two column layout for even better use of limited space, just pass `@display="columnCompressed"` to align the labels and inputs side by side.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiComboBox,
  EuiFieldText,
  EuiFilePicker,
  EuiFormRow,
  EuiPanel,
  EuiRange,
  EuiSelect,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class ColumnLayoutDemo extends Component {
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

  @tracked isSwitchChecked = false;
  @tracked comboBoxSelectionOptions = [];
  @tracked value = '20';

  @action
  onRangeChange(event) {
    this.value = event.target.value;
  }

  @action
  onSwitchChange() {
    this.isSwitchChecked = !this.isSwitchChecked;
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
      <EuiFormRow
        @label="Text field"
        @helpText="I am some friendly help text."
        @display="columnCompressed"
      >
        <EuiFieldText name="first" @isLoading={{true}} @compressed={{true}} />
      </EuiFormRow>

      <EuiFormRow @label="Select" @display="columnCompressed">
        <EuiSelect @options={{this.selectOptions}} @compressed={{true}} />
      </EuiFormRow>

      <EuiFormRow @label="File picker" @display="columnCompressed">
        <EuiFilePicker @compressed={{true}} @display="default" />
      </EuiFormRow>

      <EuiFormRow @label="Comboboxwithalonglabelname" @display="columnCompressed">
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

      <EuiFormRow @label="Range" @display="columnCompressed">
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

      <EuiFormRow @display="columnCompressed" @label="Switch">
        <EuiSwitch
          name="switch"
          @showLabel={{false}}
          @label="Switch"
          @checked={{this.isSwitchChecked}}
          @onChange={{this.onSwitchChange}}
          @compressed={{true}}
        />
      </EuiFormRow>
    </EuiPanel>
  </template>
}
```
