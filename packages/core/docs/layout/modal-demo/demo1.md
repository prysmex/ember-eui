---
order: 1
---

# Modal

<EuiText>
  Each <strong>EuiModal</strong> requires a specific set of nested child components. They can be
  omitted if necessary, but the order cannot be changed or interrupted. Modals
  come a wrapping <strong>EuiOverlayMask</strong> to obscure the content beneath, but unlike
  flyouts, modals cannot be dismissed by clicking on the overlay mask. This is
  inline with our modal usage guidelines which requires there to be a primary
  action button, even if that button simply closes the modal.
</EuiText>

```hbs template
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'basicModalActive')}}
>
  Show Modal
</EuiButton>
{{#if this.basicModalActive}}

  <EuiModal
    @onClose={{fn this.deactivateModal 'basicModalActive'}}
    @initialFocus='#focusee'
    @maxWidth='90%'
  >
    <EuiModalHeader>
      <EuiTitle @size='m'>
        Basic Modal
      </EuiTitle>
    </EuiModalHeader>
    <EuiModalBody>
      <EuiText>
        <p>
          Hello there!
        </p>
        <p>
          This modal has many
          <a id='focusee' href='#'>
            different
          </a>
          <a href='#'>
            focusable
          </a>
          <a href='#'>
            items
          </a>
          .
        </p>
      </EuiText>
    </EuiModalBody>
    <EuiModalFooter>
      <EuiButtonEmpty
        {{on 'click' (fn this.deactivateModal 'basicModalActive')}}
      >
        Cancel
      </EuiButtonEmpty>
      <EuiButton
        {{on 'click' (fn this.deactivateModal 'basicModalActive')}}
        @color='primary'
        @fill={{true}}
      >
        Submit
      </EuiButton>
    </EuiModalFooter>
  </EuiModal>
{{/if}}
<EuiSpacer />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked basicModalActive = false;

  @action
  activateModal(modal) {
    this[modal] = true;
  }

  @action
  deactivateModal(modal) {
    this[modal] = false;
  }

  @action
  reloadPage() {
    location.reload();
  }
}
```
