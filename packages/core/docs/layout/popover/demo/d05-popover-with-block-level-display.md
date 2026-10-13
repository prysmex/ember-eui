---
order: 5
---

# Popover with block level display

<EuiText>
  <p>
    Popover anchors default to <EuiCode>display: inline-block;</EuiCode> so they do not force a display on inline triggers. If you do need to change this, just add <EuiCode>@display="block"</EuiCode>
  </p>
</EuiText>

```hbs template
<EuiPopover
  @isOpen={{this.isPopoverOpen}}
  @closePopover={{this.closePopover}}
  @display='block'
>
  <:button>
    <EuiButton @fullWidth={{true}} {{on 'click' this.onButtonClick}}>
      This button is expanded
    </EuiButton>
  </:button>
  <:content>
    <div>This is a popover</div>
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
