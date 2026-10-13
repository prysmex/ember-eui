---
order: 5
---

# Setting width

<EuiText>
  <p>
    Modals start with a minimum width of <EuiCode>400px</EuiCode>, just enough to
    display form rows. They will grow to fit the contents until it reaches the
    specified <EuiCode>@maxWidth</EuiCode>, the default of which is set to the
    medium breakpoint.
  </p>
  <p>
    If the modal is not growing wide enough to fit your contents, you can pass a
    specific <EuiCode>style</EuiCode> width, just remember that modals will
    always shrink to fit the window width.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiCodeBlock, EuiModal, EuiModalBody, EuiModalFooter, EuiModalHeader, EuiModalHeaderTitle, EuiSpacer } from '@ember-eui/core/components';

export default class ModalWidthComponent extends Component {
  @tracked isModalVisible = false;

  code = `<EuiModal aria-labelledby="modalWidthTitle" style="width: 800px" @onClose={{this.closeModal}}>
  <EuiModalHeader>
    <EuiModalHeaderTitle id="modalWidthTitle"><!-- Modal title --></EuiModalHeaderTitle>
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
  <EuiButton {{on "click" this.showModal}}>Show modal with custom width</EuiButton>

  {{#if this.isModalVisible}}
    <EuiModal
      aria-labelledby="modalWidthTitle"
      style="width: 800px"
      @onClose={{this.closeModal}}
    >
      <EuiModalHeader>
        <EuiModalHeaderTitle id="modalWidthTitle">
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
