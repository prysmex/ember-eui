---
order: 8
---
# Constraining a popover inside a container

<EuiText>
    <strong>EuiPopover</strong>
    can accept a DOM element as a
    <EuiCode>container</EuiCode>
    prop and restrict the popover from overflowing that container.
  </EuiText>

```hbs template
<div>
  <EuiPanel {{did-insert (set this 'panel')}}>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.popover}}
      @closePopover={{set this 'popover' false}}
      @container={{this.panel}}
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
        Popover is positioned <EuiCode>downCenter</EuiCode> but constrained to fit within the
        panel.
      </:content>
    </EuiPopover>
    <EuiSpacer @size='xl' />
    <EuiSpacer @size='xl' />
  </EuiPanel>
</div>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo1 extends Component {
  @tracked popover = false;
  @tracked panel = null;
}
```
