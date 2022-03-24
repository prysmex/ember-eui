---
order: 10
---

```hbs template
<div>
  <EuiTitle>
    Removing the focus trap
  </EuiTitle>
  <EuiSpacer />
  <EuiText>
    If the popover should not trap focus within itself, then you can remove it
    with
    <EuiCode>ownFocus={false}</EuiCode>.
  </EuiText>
  <EuiSpacer />
  <EuiPopover
    @ownFocus={{false}}
    @isOpen={{this.popover}}
    @anchorPosition='downLeft'
    @closePopover={{set this 'popover' false}}
  >
    <:button>
      <EuiButton
        @iconType='arrowDown'
        @iconSide='right'
        {{on 'click' (set this 'popover' true)}}
      >
        Show popover
      </EuiButton>
    </:button>
    <:content>
      <EuiFormRow
        label='Generate a public snapshot?'
        id={{unique-id}}
      >
        <EuiSwitch
          name='switch'
          label='Snapshot data'
          checked={{true}}
          onChange={{noop}}
        />
      </EuiFormRow>
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
