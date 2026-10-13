---
order: 4
---

# Configuring forms

<EuiText>
  Since the child components of <strong>EuiModal</strong> are required to be in
  a specific order, you can only wrap the contents within
  <strong>EuiModalBody</strong> with the <EuiCode>&lt;form /&gt;</EuiCode>
  element. You can then hook up your submit button inside
  <strong>EuiModalFooter</strong> by adding the <EuiCode>id</EuiCode> of the
  <EuiCode>&lt;form /&gt;</EuiCode> element to the <EuiCode>form</EuiCode>
  attribute of the button. To focus the first field when the modal opens, pass
  <EuiCode>@initialFocus</EuiCode> a selector.
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiButtonEmpty, EuiFieldText, EuiForm, EuiFormRow, EuiModal, EuiModalBody, EuiModalFooter, EuiModalHeader, EuiModalHeaderTitle, EuiRange, EuiSuperSelect, EuiSwitch, EuiText } from '@ember-eui/core/components';

export default class ModalFormComponent extends Component {
  @tracked isModalVisible = false;
  @tracked isSwitchChecked = true;
  @tracked superSelectValue = 'option_one';

  superSelectOptions = [
    { value: 'option_one', inputDisplay: 'Option one' },
    { value: 'option_two', inputDisplay: 'Option two' },
    { value: 'option_three', inputDisplay: 'Option three' }
  ];

  @action
  showModal() {
    this.isModalVisible = true;
  }

  @action
  closeModal() {
    this.isModalVisible = false;
  }

  @action
  onSwitchChange() {
    this.isSwitchChecked = !this.isSwitchChecked;
  }

  @action
  onSuperSelectChange(value) {
    this.superSelectValue = value;
  }

  <template>
  <EuiButton {{on "click" this.showModal}}>Show form modal</EuiButton>

  {{#if this.isModalVisible}}
    <EuiModal
      aria-labelledby="modalFormTitle"
      @onClose={{this.closeModal}}
      @initialFocus="[name=popswitch]"
    >
      <EuiModalHeader>
        <EuiModalHeaderTitle id="modalFormTitle">
          Modal title
        </EuiModalHeaderTitle>
      </EuiModalHeader>

      <EuiModalBody>
        <EuiForm id="modalForm" @component="form">
          <EuiFormRow>
            <EuiSwitch
             
              name="popswitch"
              @label="Cool modal form"
              @checked={{this.isSwitchChecked}}
              @onChange={{this.onSwitchChange}}
            />
          </EuiFormRow>

          <EuiFormRow @label="A text field">
            <EuiFieldText name="popfirst" />
          </EuiFormRow>

          <EuiFormRow @label="Range" @helpText="Some help text for the range">
            <EuiRange @min={{0}} @max={{100}} @value={{50}} @name="poprange" />
          </EuiFormRow>

          <EuiFormRow @label="An EuiSuperSelect">
            <EuiSuperSelect
              @options={{this.superSelectOptions}}
              @valueOfSelected={{this.superSelectValue}}
              @onChange={{this.onSuperSelectChange}}
            >
              <:inputDisplay as |option|>{{option.inputDisplay}}</:inputDisplay>
              <:dropdownDisplay as |option|>
                <strong>{{option.inputDisplay}}</strong>
                <EuiText @size="s" @color="subdued">
                  <p>Has a short description giving more detail to the option.</p>
                </EuiText>
              </:dropdownDisplay>
            </EuiSuperSelect>
          </EuiFormRow>
        </EuiForm>
      </EuiModalBody>

      <EuiModalFooter>
        <EuiButtonEmpty {{on "click" this.closeModal}}>Cancel</EuiButtonEmpty>

        <EuiButton
          type="submit"
          form="modalForm"
          @fill={{true}}
          {{on "click" this.closeModal}}
        >
          Save
        </EuiButton>
      </EuiModalFooter>
    </EuiModal>
  {{/if}}
  </template>
}
```
