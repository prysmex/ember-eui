---
order: 10
---

# Removing the focus trap

<EuiText>
    If the popover should not trap focus within itself, then you can remove it
    with
    <EuiCode @language="jsx">ownFocus={false}</EuiCode>.
  </EuiText>

```hbs template
<div>
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
        @label='Generate a public snapshot?'
        @id={{(unique-id)}}
        @hasChildLabel={{false}}
      >
        <EuiSwitch
          @name='switch'
          @label='Snapshot data'
          @checked={{true}}
          @onChange={{(noop)}}
        />
      </EuiFormRow>

      <EuiFormRow
        @label='Include the following in the embed'
        @id={{(unique-id)}}
      >
        <EuiSwitch
          @name='switch'
          @label='Current time range'
          @checked={{true}}
          @onChange={{(noop)}}
        />
      </EuiFormRow>

      <EuiSpacer />

      <EuiButton @fill={{true}}>Copy IFRAME code</EuiButton>
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
