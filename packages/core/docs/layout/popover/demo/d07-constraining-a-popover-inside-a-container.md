---
order: 7
---

# Constraining a popover inside a container

<EuiText>
  <p>
    <strong>EuiPopover</strong> can accept a DOM element as a <EuiCode>@container</EuiCode> argument and restrict the popover from overflowing that container.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { tracked } from '@glimmer/tracking';
import { EuiButtonEmpty, EuiCode, EuiPanel, EuiPopover, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

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

  <template>
    <EuiPanel {{didInsert this.setPanelRef}}>
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
  </template>
}
```
