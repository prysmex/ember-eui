---
order: 3
---

# Demo 3

Popover on a fixed element
Popover content even works on position: fixed; elements. Add the repositionOnScroll boolean prop to ensure the popover realigns to the fixed button on scroll.

```hbs template
<EuiButton {{on "click" (set this.isExampleShown true)}}>
  Toggle example
</EuiButton>
{{#if this.isExampleShown}}
  <EuiPopover
    @ownFocus={{true}}
    @isOpen={{this.pop1}}
    @closePopover={{set this.pop1 false}}
    @repositionOnScroll={{true}}
    style="position: fixed; bottom: 50px; right: 50px; z-index: 10;"
  >
    <:button>
      <EuiButton
        @iconType="arrowDown"
        @iconSide="right"
        @fill={{true}}
        {{on "click" (set this.pop1 true)}}
      >
        Show fixed popover
      </EuiButton>
    </:button>
    <:content>
      <EuiPopoverTitle>
        Hello, I’m a popover title
      </EuiPopoverTitle>
      <div style="width: 300px;">
        <EuiText size="s">
          <p>
            Selfies migas stumptown hot chicken quinoa wolf green juice,
                mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
          </p>
        </EuiText>
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
}
```
