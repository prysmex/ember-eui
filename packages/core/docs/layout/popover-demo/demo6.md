---
order: 6
---

```hbs template
<div>
  <EuiTitle>
    Panel class name
  </EuiTitle>
  <EuiSpacer />
  <EuiText>
    Use the <EuiCode>panelClassName</EuiCode> prop to pass a custom class to the panel containing the popover contents.
  </EuiText>
  <EuiSpacer />
  <EuiPopover
    @ownFocus={{true}}
    @isOpen={{this.popover}}
    @anchorPosition='downLeft'
    @panelClasses='bg-blue'
    @closePopover={{set this 'popover' false}}
  >
    <:button>
      <EuiButton
        @iconType='arrowDown'
        @iconSide='right'
        {{on 'click' (set this 'popover' true)}}
      >
        Text scaling
      </EuiButton>
    </:button>
    <:content>
      This has a custom class that applies some css.
    </:content>
  </EuiPopover>
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
