---
order: 1
---

<EuiText>
  <p>
    Use the
    <strong>EuiPopover</strong>
    component to hide controls or options behind a clickable element. A popover
    is temporary so keep tasks simple and narrowly focused.
   </p>
   <p> 
    While the visibility
    of the popover is maintained by the consuming application, popovers will
    automatically close when clicking outside of the popover bounds. Therefore
    all work done in a popover should automatically be saved. 
    </p>
    <p>
    Avoid popover
    inception (popover triggering another popover), and instead use a
    EuiContextMenu to swap the popover panel content.
    </p>

</EuiText>

```hbs template
<div>
  <EuiPopover
    @ownFocus={{true}}
    @isOpen={{this.popover}}
    @anchorPosition='downCenter'
    @closePopover={{set this 'popover' false}}
  >
    <:button>
      <EuiButton
        @iconType='arrowDown'
        @iconSide='right'
        {{on 'click' (set this 'popover' true)}}
      >
        Show Popover
      </EuiButton>
    </:button>
    <:content>
      <EuiText @size="m" style="width: 300px;">
        <p>
          Popover content that’s wider than the default width
        </p>
      </EuiText>
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
