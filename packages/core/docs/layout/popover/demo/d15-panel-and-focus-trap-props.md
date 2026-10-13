---
order: 15
---

# Panel and focus trap props

<EuiText>

`@panelProps` passes props to the panel: `className`, `css`, `tabIndex`,
`role`, `aria-modal`, and any `aria-*`, `data-*` or `on<Event>` key. A
`@panelProps` `aria-modal` other than `true` makes the popover focus its panel
like `@ownFocus` does. `@focusTrapProps` configures the focus trap
(`returnFocus`, `shards`, `disabled`, `onEscapeKey`, `onClickOutside`, `initialFocus`)
and replaces the popover's own handling, so here Escape and outside clicks are
reported but you decide when to close. `@onPositionChange` reports the side the
panel ended up on.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiPopover, EuiText } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class PopoverPropsDemo extends Component {
  @tracked isOpen = false;
  @tracked position = '';
  @tracked log = '';

  panelProps = {
    className: 'my-popover-panel',
    'data-test-subj': 'propsPopover',
    'aria-describedby': 'propsPopoverHelp'
  };

  focusTrapProps = {
    returnFocus: true,
    onEscapeKey: () => (this.log = 'Escape pressed'),
    onClickOutside: () => (this.log = 'Clicked outside')
  };

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  @action
  onPositionChange(position) {
    this.position = position;
  }

  <template>
    <EuiPopover
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @panelProps={{this.panelProps}}
      @focusTrapProps={{this.focusTrapProps}}
      @onPositionChange={{this.onPositionChange}}
    >
      <:button>
        <EuiButton {{on 'click' this.toggle}}>Toggle popover</EuiButton>
      </:button>
      <:content>
        <EuiText @size='s'>
          <p id='propsPopoverHelp'>Opened on the <strong>{{this.position}}</strong> side.</p>
          <p>{{this.log}}</p>
          <EuiButton @size='s' {{on 'click' this.close}}>Close</EuiButton>
        </EuiText>
      </:content>
    </EuiPopover>
  </template>
}
```
