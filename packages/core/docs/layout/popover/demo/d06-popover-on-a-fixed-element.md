---
order: 6
---

# Popover on a fixed element

<EuiText>
  <p>
    Popover content even works on <EuiCode>position: fixed;</EuiCode> elements. Add the <EuiCode>@repositionOnScroll</EuiCode> boolean argument to ensure the popover realigns to the fixed button on scroll.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiButtonEmpty, EuiPopover } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class PopoverDemo extends Component {
  @tracked isExampleShown = false;
  @tracked isPopoverOpen = false;

  @action
  toggleExample() {
    this.isExampleShown = !this.isExampleShown;
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
    <EuiButton {{on 'click' this.toggleExample}}>Toggle example</EuiButton>
    {{#if this.isExampleShown}}
      <EuiPopover
        @isOpen={{this.isPopoverOpen}}
        @closePopover={{this.closePopover}}
        @repositionOnScroll={{true}}
        style='position: fixed; bottom: 50px; right: 50px; z-index: 10;'
      >
        <:button>
          <EuiButtonEmpty
            @iconType='help'
            @iconSide='right'
            {{on 'click' this.onButtonClick}}
          >
            Show fixed popover
          </EuiButtonEmpty>
        </:button>
        <:content>
          <div>This popover scrolls with the button element!</div>
        </:content>
      </EuiPopover>
    {{/if}}
  </template>
}
```
