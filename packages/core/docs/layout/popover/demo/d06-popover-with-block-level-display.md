---
order: 6
---
# Popover with block level display

<EuiText>
    Popover anchors default to <EuiCode>display: inline-block;</EuiCode> so they do not force a display on inline triggers. If you do need to change this, just add <EuiCode>display="block"</EuiCode>
  </EuiText>

```hbs template
<div>
  <EuiPopover
    @ownFocus={{true}}
    @isOpen={{this.popover}}
    @anchorPosition='downCenter'
    @display='block'
    @closePopover={{set this 'popover' false}}
  >
    <:button>
      <EuiButton
        @iconSide='right'
        @fullWidth={{true}}
        {{on 'click' (set this 'popover' true)}}
      >
        This button is expanded
      </EuiButton>
    </:button>
    <:content>
      This is a popover
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
