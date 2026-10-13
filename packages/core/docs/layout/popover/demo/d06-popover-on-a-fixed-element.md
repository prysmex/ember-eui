---
order: 6
---

# Popover on a fixed element

<EuiText>
  <p>
    Popover content even works on <EuiCode>position: fixed;</EuiCode> elements. Add the <EuiCode>@repositionOnScroll</EuiCode> boolean argument to ensure the popover realigns to the fixed button on scroll.
  </p>
</EuiText>

```hbs template
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
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

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
}
```
