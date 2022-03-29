---
order: 4
---

# Loading modal

<EuiText>
  <strong>EuiConfirmModal</strong> supports being able to apply loading and disabled states to the confirm button with the <EuiCode>confirmButtonDisabled</EuiCode> and <EuiCode>isLoading</EuiCode> props respectively. This is helpful to indicate the fetching of data and/or to wait for a user's input before enabling the confirm action.
</EuiText>

```hbs template
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'loadingModalActive')}}
>
  Activate Loading Modal
</EuiButton>
{{#if this.loadingModalActive}}

  <EuiConfirmModal
    @title='Refresh the page?'
    @onConfirm={{this.reloadPage}}
    @buttonColor='primary'
    @confirmButtonText='Refresh'
    @cancelButtonText='Cancel'
    @isLoading={{this.isLoading}}
    @onCancel={{fn this.deactivateModal 'loadingModalActive'}}
  >
    <EuiText>
      Eui Modal with isLoading true and a timeout for removing is loading
      spinner
    </EuiText>
  </EuiConfirmModal>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked loadingModalActive = false;
  @tracked isLoading = true;

  @action
  activateModal(modal) {
    this[modal] = true;
    setTimeout(() => {
      this.isLoading = false;
    }, 3500);
  }

  @action
  deactivateModal(modal) {
    this[modal] = false;
    this.isLoading = true;
  }

  @action
  reloadPage() {
    location.reload();
  }
}
```
