---
order: 5
---

# Widths

<EuiText>

Modals are at least 400px wide and grow with their content up to a maximum. `@maxWidth={{true}}` uses EUI's default maximum, a CSS width sets your own, and a `style` width fixes it; modals always shrink to fit small windows.

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
