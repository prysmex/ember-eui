---
order: 9
---

# Setting an initial focus

<EuiText>
  <p>
    If you want a specific child element of the popover to immediately gain focus when the popover is open, use the <EuiCode>@initialFocus</EuiCode> argument to pass either a selector or DOM node.
  </p>
</EuiText>

<EuiSpacer @size='m' />

<EuiCallOut @title='Accessibility recommendation' @color='primary' @iconType='accessibility'>
  <p>
    It can be jarring for keyboard and screen reader users to immediately land on an element with no other context. To alleviate this, ensure that your initial focus target makes sense alone or is the primary goal of the popover.
  </p>
</EuiCallOut>

```hbs template
<EuiPopover
  @initialFocus='#name'
  @isOpen={{this.isPopoverOpen}}
  @closePopover={{this.closePopover}}
>
  <:button>
    <EuiButtonEmpty
      @iconType='help'
      @iconSide='right'
      {{on 'click' this.onButtonClick}}
    >
      Show popover
    </EuiButtonEmpty>
  </:button>
  <:content>
    <EuiFormRow @label='Enter name' @id='name'>
      <EuiFieldText @compressed={{true}} @name='input' />
    </EuiFormRow>

    <EuiSpacer />

    <EuiButton @size='s' @fill={{true}}>
      Submit
    </EuiButton>
  </:content>
</EuiPopover>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo extends Component {
  @tracked isPopoverOpen = false;

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }
}
```
