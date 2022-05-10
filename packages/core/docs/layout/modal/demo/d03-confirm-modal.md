---
order: 3
---

# Confirm Modal

```hbs template

<!-- buttons -->

<EuiFlexGroup>
  <EuiFlexItem>
    <EuiButton
      @color='primary'
      {{on 'click' (fn this.activateModal 'confirmModalActive')}}
    >
      Show confirm modal
    </EuiButton>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiButton
      @color='primary'
      {{on 'click' (fn this.activateModal 'dangerousConfirmModalActive')}}
    >
      Show dangerous confirm modal
    </EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>

<!-- modals -->

{{#if this.confirmModalActive}}
  <EuiConfirmModal
    @title='Do this thing'
    @onConfirm={{fn this.deactivateModal 'confirmModalActive'}}
    @buttonColor='primary'
    @confirmButtonText='Yes, do it'
    @cancelButtonText="No, don't do it"
    @onCancel={{fn this.deactivateModal 'confirmModalActive'}}
  >
    <EuiText>
      <p>You are about to do something</p>
      <p>Are you sure you want to do this?</p>
    </EuiText>
  </EuiConfirmModal>
{{/if}}

{{#if this.dangerousConfirmModalActive}}
  <EuiConfirmModal
    @title='Do this destructive thing'
    @onConfirm={{fn this.deactivateModal 'dangerousConfirmModalActive'}}
    @buttonColor='danger'
    @confirmButtonText='Yes, do it'
    @cancelButtonText="No, don't do it"
    @onCancel={{fn this.deactivateModal 'dangerousConfirmModalActive'}}
  >
    <EuiText>
      <p>You’re about to destroy something.</p>
      <p>Are you sure you want to do this?</p>
    </EuiText>
  </EuiConfirmModal>
{{/if}}

```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked confirmModalActive = false;
  @tracked dangerousConfirmModalActive = false;

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
