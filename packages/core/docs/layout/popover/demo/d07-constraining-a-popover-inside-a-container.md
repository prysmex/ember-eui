---
order: 7
---

# Constraining a popover inside a container

<EuiText>
  <p>
    <strong>EuiPopover</strong> can accept a DOM element as a <EuiCode>@container</EuiCode> argument and restrict the popover from overflowing that container.
  </p>
</EuiText>

```hbs template
<EuiPanel {{did-insert this.setPanelRef}}>
  <EuiPopover
    @isOpen={{this.isPopoverOpen}}
    @closePopover={{this.closePopover}}
    @container={{this.panelRef}}
  >
    <:button>
      <EuiButtonEmpty
        @iconType='help'
        @iconSide='right'
        style='position: relative; left: 50px;'
        {{on 'click' this.onButtonClick}}
      >
        Show constrained popover
      </EuiButtonEmpty>
    </:button>
    <:content>
      <div>
        Popover is positioned <EuiCode>downCenter</EuiCode> but constrained to fit within the panel.
      </div>
    </:content>
  </EuiPopover>
  {{! create adequate room for the popover }}
  <EuiSpacer @size='xxl' />
  <EuiSpacer @size='xxl' />
</EuiPanel>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo extends Component {
  @tracked isPopoverOpen = false;
  @tracked panelRef = null;

  @action
  setPanelRef(element) {
    this.panelRef = element;
  }

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
