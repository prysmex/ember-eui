---
order: 10
---

# Custom outside click behavior

<EuiText>
  <p>
    If you do not wish the popover to auto-close on outside clicks, you can use <EuiCode>@focusTrapOptions</EuiCode> to customize this behavior: its <EuiCode>onClickOutside</EuiCode> callback replaces the default close. The below example triggers a confirmation modal which can leave the popover open if the user presses 'No'.
  </p>
</EuiText>

```hbs template
<EuiPopover
  @isOpen={{this.isPopoverOpen}}
  @closePopover={{this.closePopover}}
  @focusTrapOptions={{hash
    clickOutsideDeactivates=false
    onClickOutside=this.showModal
  }}
>
  <:button>
    <EuiButtonEmpty
      @iconType='help'
      @iconSide='right'
      {{on 'click' this.togglePopover}}
    >
      This popover toggles a confirm modal on close
    </EuiButtonEmpty>
  </:button>
  <:content>
    <EuiText>
      <p>
        Clicking outside this popover toggles a confirm modal.
        <br />
        The confirm modal either keeps the popover open or closes the popover.
      </p>
    </EuiText>
  </:content>
</EuiPopover>

{{#if this.isModalVisible}}
  <EuiConfirmModal
    @title='You have unsaved work'
    @onCancel={{this.closeModal}}
    @onConfirm={{this.confirmModal}}
    @cancelButtonText="No, don't do it"
    @confirmButtonText='Yes, do it'
    @defaultFocusedButton='cancel'
  >
    <p>Are you sure you to close the popover?</p>
  </EuiConfirmModal>
{{/if}}
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo extends Component {
  @tracked isPopoverOpen = false;
  @tracked isModalVisible = false;

  @action
  togglePopover() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  showModal() {
    this.isModalVisible = true;
  }

  @action
  closeModal() {
    this.isModalVisible = false;
  }

  @action
  confirmModal() {
    this.isModalVisible = false;
    this.isPopoverOpen = false;
  }
}
```
