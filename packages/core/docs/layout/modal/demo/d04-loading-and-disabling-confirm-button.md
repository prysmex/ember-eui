---
order: 4
---

# Loading and disabling the confirm button

<EuiText>

`@isLoading` shows a spinner in the confirm button while the action runs; `@confirmButtonDisabled` disables it, e.g. until the user types a confirmation.

</EuiText>

```hbs template
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'modalActive')}}
>
  Show loading confirm modal
</EuiButton>
{{#if this.modalActive}}
  <EuiConfirmModal
    @title='Delete the EUI repo?'
    @onConfirm={{this.alertMessage}}
    @buttonColor='danger'
    @confirmButtonText='Delete'
    @cancelButtonText='Cancel'
    @isLoading={{this.isLoading}}
    @confirmButtonDisabled={{(if
      (eq this.textValue 'delete')
      false
      true
    )}}
    @onCancel={{fn this.deactivateModal 'modalActive'}}
  >
    <EuiText>
      {{#let
        (unique-id)
      as |textId|}}
        <EuiFormRow @label="Type the word 'delete' to confirm" @id={{textId}}>
          <EuiFieldText
            @value={{this.textValue}}
            @id={{textId}}
            @isLoading={{this.isLoading}}
            {{on 'input' (pick 'target.value' (set this 'textValue'))}}
          />
          
        </EuiFormRow>
      {{/let}}
    </EuiText>
  </EuiConfirmModal>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked modalActive = false;
  @tracked isLoading = true;

  @action
  activateModal(modal) {
    this[modal] = true
    this.isLoading = true
    setTimeout(() => {
      this.isLoading = false
    }, 1000);
  }

  @action
  deactivateModal(modal) {
    this[modal] = false;
  }

  @action
  alertMessage() {
    confirm('Shame on you!')
  }
}
```
