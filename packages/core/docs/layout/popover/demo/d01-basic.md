---
order: 1
---

# Basic popover

<EuiText>
  <p>
    Use the <strong>EuiPopover</strong> component to hide controls or options behind a clickable element. A popover is temporary so keep tasks simple and narrowly focused.
  </p>
  <p>
    While the visibility of the popover is maintained by the consuming application, popovers will automatically close when clicking outside of the popover bounds. Therefore all work done in a popover should automatically be saved. Toggle <EuiCode>@isOpen</EuiCode> from the button in the <EuiCode>&lt;:button&gt;</EuiCode> block and set it to <EuiCode>false</EuiCode> in <EuiCode>@closePopover</EuiCode>.
  </p>
  <p>
    Avoid popover inception (popover triggering another popover), and instead use a <strong>EuiContextMenu</strong> to swap the popover panel content.
  </p>
  <p><strong>Popovers have three accessibility requirements:</strong></p>
  <ul>
    <li>Popover triggers <strong>must</strong> be anchored to elements that accept keyboard focus.</li>
    <li>Popovers can contain interactive elements. They <strong>must</strong> be controlled by a click handler.</li>
    <li>Popovers must not be activated by hover or focus events.</li>
  </ul>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButtonEmpty, EuiPopover, EuiText } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class PopoverDemo extends Component {
  @tracked isPopoverOpen = false;
  @action
  toggle(name) {
    this[name] = !this[name];
  }

  @action
  close(name) {
    this[name] = false;
  }

  <template>
    <EuiPopover
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{fn this.close 'isPopoverOpen'}}
    >
      <:button>
        <EuiButtonEmpty
          @iconType='documentation'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen')}}
        >
          How it works
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiText style='width: 300px;'>
          <p>Popover content that&rsquo;s wider than the default width</p>
        </EuiText>
      </:content>
    </EuiPopover>
  </template>
}
```
