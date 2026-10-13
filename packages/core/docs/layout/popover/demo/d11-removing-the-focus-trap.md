---
order: 11
---

# Removing the focus trap

<EuiText>
  <p>
    If the popover should not trap focus within itself, then you can remove it with <EuiCode>@ownFocus=&#123;&#123;false&#125;&#125;</EuiCode>.
  </p>
</EuiText>

<EuiSpacer @size='m' />

<EuiCallOut @title='Accessibility warning' @color='warning' @iconType='accessibility'>
  <p>
    Removing <EuiCode>@ownFocus</EuiCode> makes it difficult for keyboard-only and screen reader users to navigate to and from your popover.
  </p>
</EuiCallOut>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiButtonEmpty, EuiFormRow, EuiPopover, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class PopoverDemo extends Component {
  @tracked isPopoverOpen = false;

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  noop() {}

  <template>
    <EuiPopover
      @ownFocus={{false}}
      @initialFocus='#focusId'
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
    >
      <:button>
        <EuiButtonEmpty
          @iconType='help'
          @iconSide='right'
          {{on 'click' this.onButtonClick}}
        >
          Show popover
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiFormRow
          @label='Generate a public snapshot?'
          @id='focusId'
          @hasChildLabel={{false}}
        >
          <EuiSwitch
            @name='switch'
            @label='Snapshot data'
            @checked={{true}}
            @onChange={{this.noop}}
          />
        </EuiFormRow>

        <EuiFormRow @label='Include the following in the embed'>
          <EuiSwitch
            @name='switch'
            @label='Current time range'
            @checked={{true}}
            @onChange={{this.noop}}
          />
        </EuiFormRow>

        <EuiSpacer />

        <EuiButton @fill={{true}}>Copy IFRAME code</EuiButton>
      </:content>
    </EuiPopover>
  </template>
}
```
