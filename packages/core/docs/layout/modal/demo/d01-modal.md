---
order: 1
---

<!-- <EuiText>
Each <strong>EuiModal</strong> requires a specific set of nested child components. They can be omitted if necessary, but the order cannot be changed or interrupted.

Modals come a wrapping <strong>EuiOverlayMask</strong> to obscure the content beneath, but unlike flyouts, modals cannot be dismissed by clicking on the overlay mask. This is inline with our modal usage guidelines which requires there to be a primary action button, even if that button simply closes the modal.
</EuiText> -->

```hbs template
<EuiButton
  @color='primary'
  {{on 'click' this.activateModal}}
>
  Show modal
</EuiButton>

{{#if this.isActive}}

  <EuiModal
    @onClose={{this.deactivateModal}}
  >
    <EuiModalHeader>
      <EuiTitle @size='m'>
        Modal title
      </EuiTitle>
    </EuiModalHeader>
    <EuiModalBody>
      <EuiText>
        <p>
          This modal has the following setup:
        </p>
        <p>
          <EuiCodeBlock @isCopyable={{true}}>
            some code here...
          </EuiCodeBlock>
        </p>
      </EuiText>
    </EuiModalBody>
    <EuiModalFooter>
      <EuiButton
        {{on 'click' this.deactivateModal}}
        @color='primary'
        @fill={{true}}
      >
        Close
      </EuiButton>
    </EuiModalFooter>
  </EuiModal>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked isActive = false;

  @action
  activateModal(modal) {
    this.isActive = true;
  }

  @action
  deactivateModal(modal) {
    this.isActive = false;
  }

}
```
