---
order: 11
---

```hbs template
<div>
  <EuiTitle>
    Popover using an HTMLElement as the anchor
  </EuiTitle>
  <EuiSpacer />
  <EuiText>
    <strong>EuiWrappingPopover</strong> is an extra popover component that allows any existing
    DOM element to be passed as the <EuiCode>button</EuiCode>prop.
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
      <EuiFormRow label='Generate a public snapshot?' id={{unique-id}}>
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
