---
order: 3
---

# Loading and disabling confirm button

<EuiText>
  <strong>EuiConfirmModal</strong> supports being able to apply loading and
  disabled states to the confirm button with the
  <EuiCode>@confirmButtonDisabled</EuiCode> and
  <EuiCode>@isLoading</EuiCode> arguments respectively. This is helpful to
  indicate the fetching of data and/or to wait for a user's input before
  enabling the confirm action.
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiConfirmModal, EuiFieldText, EuiFormRow } from '@ember-eui/core/components';

export default class ModalLoadingConfirmComponent extends Component {
  @tracked isLoading = false;
  @tracked isModalVisible = false;
  @tracked value = '';

  titleProps = { id: 'deleteModalTitle' };

  timeoutId = null;

  get isConfirmDisabled() {
    return this.value.toLowerCase() !== 'delete';
  }

  @action
  showModal() {
    this.isModalVisible = true;
    this.isLoading = true;
    // Simulate a remotely-executed search.
    this.timeoutId = setTimeout(() => {
      this.isLoading = false;
    }, 1200);
  }

  @action
  closeModal() {
    this.isModalVisible = false;
    this.isLoading = false;
    this.value = '';
    clearTimeout(this.timeoutId);
  }

  @action
  confirm() {
    this.closeModal();
    window.alert('Shame on you!');
  }

  @action
  onChange(event) {
    this.value = event.target.value;
  }

  willDestroy() {
    super.willDestroy(...arguments);
    clearTimeout(this.timeoutId);
  }

  <template>
  <EuiButton {{on "click" this.showModal}}>Show loading confirm modal</EuiButton>

  {{#if this.isModalVisible}}
    <EuiConfirmModal
      aria-labelledby="deleteModalTitle"
      @title="Delete the EUI repo?"
      @titleProps={{this.titleProps}}
      @onCancel={{this.closeModal}}
      @onConfirm={{this.confirm}}
      @confirmButtonText="Delete"
      @cancelButtonText="Cancel"
      @buttonColor="danger"
      @initialFocus="[name=delete]"
      @confirmButtonDisabled={{this.isConfirmDisabled}}
      @isLoading={{this.isLoading}}
    >
      <EuiFormRow @label="Type the word 'delete' to confirm">
        <EuiFieldText
          name="delete"
          @isLoading={{this.isLoading}}
          @value={{this.value}}
          {{on "input" this.onChange}}
        />
      </EuiFormRow>
    </EuiConfirmModal>
  {{/if}}
  </template>
}
```
