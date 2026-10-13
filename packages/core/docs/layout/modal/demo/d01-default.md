---
order: 1
---

# Default

<EuiCallOut @title="Accessibility requirement" @iconType="accessibility" @color="warning">
  Use <code>aria-labelledby</code> pointing at the modal title's id to ensure
  the modal is announced to screen readers.
</EuiCallOut>

<EuiSpacer />

<EuiText>
  Modals use an <strong>EuiOverlayMask</strong> to obscure content beneath.
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiCodeBlock, EuiModal, EuiModalBody, EuiModalFooter, EuiModalHeader, EuiModalHeaderTitle, EuiSpacer } from '@ember-eui/core/components';

export default class ModalDefaultComponent extends Component {
  @tracked isModalVisible = false;

  code = `<EuiModal aria-labelledby="modalTitle" @onClose={{this.closeModal}}>
  <EuiModalHeader>
    <EuiModalHeaderTitle id="modalTitle"><!-- Modal title --></EuiModalHeaderTitle>
  </EuiModalHeader>

  <EuiModalBody>
    <!-- Modal body -->
  </EuiModalBody>

  <EuiModalFooter>
    <EuiButton @fill={{true}} {{on "click" this.closeModal}}>
      Close
    </EuiButton>
  </EuiModalFooter>
</EuiModal>`;

  @action
  showModal() {
    this.isModalVisible = true;
  }

  @action
  closeModal() {
    this.isModalVisible = false;
  }

  <template>
  <EuiButton {{on "click" this.showModal}}>Show modal</EuiButton>

  {{#if this.isModalVisible}}
    <EuiModal aria-labelledby="modalTitle" @onClose={{this.closeModal}}>
      <EuiModalHeader>
        <EuiModalHeaderTitle id="modalTitle">
          Modal title
        </EuiModalHeaderTitle>
      </EuiModalHeader>

      <EuiModalBody>
        This modal has the following setup:
        <EuiSpacer />
        <EuiCodeBlock @language="html" @isCopyable={{true}}>{{this.code}}</EuiCodeBlock>
      </EuiModalBody>

      <EuiModalFooter>
        <EuiButton @fill={{true}} {{on "click" this.closeModal}}>
          Close
        </EuiButton>
      </EuiModalFooter>
    </EuiModal>
  {{/if}}
  </template>
}
```
