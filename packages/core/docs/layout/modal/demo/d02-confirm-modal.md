---
order: 2
---

# Confirm modal

<EuiText>
  Use the <strong>EuiConfirmModal</strong> to ask the user to confirm a
  decision. It is a contextual wrapper around <strong>EuiModal</strong> that
  provides some helpful arguments for filling in common modal pieces. By
  default, the button color indicates a positive or neutral action. Change the
  <EuiCode>@buttonColor</EuiCode> argument to <EuiCode>danger</EuiCode> to
  indicate a destructive action.
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiConfirmModal, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

export default class ModalConfirmComponent extends Component {
  @tracked isModalVisible = false;
  @tracked isDestroyModalVisible = false;

  // `@titleProps` puts attributes on the title element: here the id that
  // `aria-labelledby` points at.
  titleProps = { id: 'confirmModalTitle' };
  destroyTitleProps = { id: 'destroyModalTitle' };

  @action
  showModal() {
    this.isModalVisible = true;
  }

  @action
  closeModal() {
    this.isModalVisible = false;
  }

  @action
  showDestroyModal() {
    this.isDestroyModalVisible = true;
  }

  @action
  closeDestroyModal() {
    this.isDestroyModalVisible = false;
  }

  <template>
  <EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="xs">
    <EuiFlexItem @grow={{false}}>
      <EuiButton {{on "click" this.showModal}}>Show confirm modal</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiButton {{on "click" this.showDestroyModal}}>
        Show dangerous confirm modal
      </EuiButton>
    </EuiFlexItem>
  </EuiFlexGroup>

  {{#if this.isModalVisible}}
    <EuiConfirmModal
      style="width: 600px"
      aria-labelledby="confirmModalTitle"
      @title="Update subscription to Platinum?"
      @titleProps={{this.titleProps}}
      @onCancel={{this.closeModal}}
      @onConfirm={{this.closeModal}}
      @cancelButtonText="Cancel"
      @confirmButtonText="Update subscription"
      @defaultFocusedButton="confirm"
    >
      <p>
        Your subscription and benefits increase immediately. If you change to a
        lower subscription later, it will not take affect until the next billing
        cycle.
      </p>
    </EuiConfirmModal>
  {{/if}}

  {{#if this.isDestroyModalVisible}}
    <EuiConfirmModal
      aria-labelledby="destroyModalTitle"
      @title="Discard dashboard changes?"
      @titleProps={{this.destroyTitleProps}}
      @onCancel={{this.closeDestroyModal}}
      @onConfirm={{this.closeDestroyModal}}
      @cancelButtonText="Keep editing"
      @confirmButtonText="Discard changes"
      @buttonColor="danger"
      @defaultFocusedButton="confirm"
    >
      <p>You will lose all unsaved changes made to this dashboard.</p>
    </EuiConfirmModal>
  {{/if}}
  </template>
}
```
