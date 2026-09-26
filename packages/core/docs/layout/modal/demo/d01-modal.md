---
order: 1
---

# Modal

<EuiText>

Open the modal from a button and render it inside `{{#if}}`. `EuiModalHeader`, `EuiModalBody` and `EuiModalFooter` lay out its parts; the body scrolls when the content is long.

</EuiText>

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
