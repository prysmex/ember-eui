---
order: 3
---
```hbs template
<EuiTitle>
  Confirm Modal
</EuiTitle>
<EuiSpacer />
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'confirmModalActive')}}
>
  Show Confirm Modal
</EuiButton>
{{#if this.confirmModalActive}}
  <EuiConfirmModal
    @title='Refresh the page?'
    @onConfirm={{this.reloadPage}}
    @buttonColor='primary'
    @confirmButtonText='Refresh'
    @cancelButtonText='Cancel'
    @onCancel={{fn this.deactivateModal 'confirmModalActive'}}
  >
    <EuiText>
      This action will trash all unsaved changes
    </EuiText>
  </EuiConfirmModal>

{{/if}}
<EuiSpacer />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked confirmModalActive = false;

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
