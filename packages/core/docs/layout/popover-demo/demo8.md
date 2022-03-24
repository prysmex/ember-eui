---
order: 8
---

```hbs template
<div>
  <EuiTitle>
    Constraining a popover inside a container
  </EuiTitle>
  <EuiSpacer />
  <EuiText>
    <strong>EuiPopover</strong> can accept a React or DOM element as a <EuiCode>container</EuiCode> prop and restrict the popover from overflowing that container.
  </EuiText>
  <EuiSpacer />
  <EuiPanel>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.popover}}
      @closePopover={{set this 'popover' false}}
      @container=".euiPanel"
    >
      <:button>
        <EuiButton
          @iconType='arrowDown'
          @iconSide='right'
          {{on 'click' (set this 'popover' true)}}
        >
          Show constrained popover
        </EuiButton>
      </:button>
      <:content>
        Popover is positioned downCenter but constrained to fit within the panel.
      </:content>
    </EuiPopover>
    <EuiSpacer @size="xl" />
    <EuiSpacer @size="xl" />
  </EuiPanel>
</div>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo1 extends Component {
  @tracked popover = false;
}
```
