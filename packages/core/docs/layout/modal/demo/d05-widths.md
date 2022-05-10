---
order: 5
---

# Widths

<EuiText>
  Modals start with a minimum width of 400px, just enough to display form rows.
  They will grow to fit the contents until it reaches the specified maxWidth,
  the default of which is set to the medium breakpoint. If the modal is not
  growing wide enough to fit your contents, you can pass a specific style.width,
  just remember that modals will always shrink to fit the window width.
</EuiText>

```hbs template
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'modalActive')}}
>
  Show modal with custom width
</EuiButton>
{{#if this.modalActive}}

  <EuiModal
    @onClose={{fn this.deactivateModal 'modalActive'}}
    style='width: {{this.width}}px'
  >
    <EuiModalHeader>
      <EuiTitle>
        Modal title
      </EuiTitle>
    </EuiModalHeader>
    <EuiModalBody>
      This modal has the following setup:
      <EuiSpacer/>
      <EuiCodeBlock @isCopyable={{true}}>
        {{this.code}}
      </EuiCodeBlock>
    </EuiModalBody>
    <EuiModalFooter>
      <EuiButton
        {{on 'click' (fn this.deactivateModal 'modalActive')}}
        @color='primary'
        @fill={{true}}
      >
        close
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
  @tracked modalActive = false;
  width = 800

  code = `
    <EuiModal style='width: ${this.width}'>...</EuiModal>
  `

  @action
  activateModal(modal) {
    this[modal] = true;
  }

  @action
  deactivateModal(modal) {
    this[modal] = false;
  }
}
```
