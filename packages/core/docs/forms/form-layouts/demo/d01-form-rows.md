---
order: 1
---

# Form rows

<EuiText>

Use the `EuiFormRow` component to easily associate form components with labels, help text, and error text.

Use the `EuiForm` component to group `EuiFormRow`s. By default, `EuiForm` will render as a simple div unless you pass `@tagName="form"`.

**`EuiFormRow` controls the child `id`.** `EuiFormRow` composes related ids for the associated labels and help texts based on the `@id` passed on `EuiFormRow` and passes it down to the child form element.

**Accessibility requirement.** Whenever possible, pass a `@label` to `EuiFormRow`. If not using the label, you must instead apply an `aria-label` directly to the wrapped form control, or an `aria-labelledby` with the text node ID of an external label.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiCheckboxGroup,
  EuiFieldText,
  EuiFilePicker,
  EuiForm,
  EuiFormRow,
  EuiLink,
  EuiRange,
  EuiSelect,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class FormRowsDemo extends Component {
  selectOptions = [
    { value: 'option_one', text: 'Option one' },
    { value: 'option_two', text: 'Option two' },
    { value: 'option_three', text: 'Option three' },
  ];

  checkboxes = [
    { id: 'formRowCheckboxItem-first', label: 'Option one' },
    { id: 'formRowCheckboxItem-second', label: 'Option two is checked by default' },
    { id: 'formRowCheckboxItem-third', label: 'Option three' },
  ];

  @tracked isSwitchChecked = false;
  @tracked checkboxIdToSelectedMap = { 'formRowCheckboxItem-second': true };

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
  onSubmit(event) {
    event.preventDefault();
  }

  noop = () => {};

  <template>
    <EuiForm @tagName="form" {{on "submit" this.onSubmit}}>
      <EuiFormRow @label="Text field" @helpText="I am some friendly help text.">
        <EuiFieldText name="first" />
      </EuiFormRow>

      <EuiFormRow @label="Disabled through form row" @isDisabled={{true}}>
        <EuiFieldText name="last" />
      </EuiFormRow>

      <EuiFormRow @label="Select (with no initial selection)">
        <:labelAppend><EuiLink>Link to some help</EuiLink></:labelAppend>
        <:field>
          <EuiSelect
            @hasNoInitialSelection={{true}}
            @options={{this.selectOptions}}
            {{on "change" this.noop}}
          />
        </:field>
      </EuiFormRow>

      <EuiFormRow @label="File picker">
        <EuiFilePicker />
      </EuiFormRow>

      <EuiFormRow @label="Range">
        <EuiRange @min={{0}} @max={{100}} name="range" />
      </EuiFormRow>

      <EuiSpacer />

      <EuiCheckboxGroup
        @options={{this.checkboxes}}
        @idToSelectedMap={{this.checkboxIdToSelectedMap}}
        @onChange={{this.onCheckboxChange}}
        @legend="Checkbox groups should use the legend argument instead of form row"
      />

      <EuiSpacer />

      <EuiFormRow
        @label="Use a switch instead of a single checkbox"
        @hasChildLabel={{false}}
      >
        <EuiSwitch
          name="switch"
          @label="Setting name"
          @checked={{this.isSwitchChecked}}
          @onChange={{this.onSwitchChange}}
        />
      </EuiFormRow>

      <EuiSpacer />

      <EuiButton @type="submit" @fill={{true}}>Save form</EuiButton>
    </EuiForm>
  </template>
}
```
