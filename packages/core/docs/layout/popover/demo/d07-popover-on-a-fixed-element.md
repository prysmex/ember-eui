---
order: 7
---

# Popover on a fixed element

<EuiText>
  Popover content even works on <EuiCode>position: fixed;</EuiCode>
  elements. Add the <EuiCode>repositionOnScroll</EuiCode> boolean prop to ensure the popover
  realigns to the fixed button on scroll.
</EuiText>

```hbs template
<EuiButton {{on 'click' this.toggleExampleShown}}>
  Toggle example
</EuiButton>
{{#if this.isExampleShown}}
  <EuiPopover
    @ownFocus={{true}}
    @isOpen={{this.pop1}}
    @closePopover={{set this 'pop1' false}}
    @repositionOnScroll={{true}}
    style='position: fixed; bottom: 50px; right: 50px; z-index: 10;'
  >
    <:button>
      <EuiButton
        @iconType='arrowDown'
        @iconSide='right'
        @fill={{true}}
        {{on 'click' (set this 'pop1' true)}}
      >
        Show fixed popover
      </EuiButton>
    </:button>
    <:content>
      <div>
        This popover scrolls with the button element!
      </div>
    </:content>
  </EuiPopover>
{{/if}}
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo1 extends Component {
  @tracked isExampleShown = false;
  @tracked pop2 = false;
  @tracked pop3 = false;

  @action
  toggleExampleShown() {
    this.isExampleShown = !this.isExampleShown
  }
}
```
