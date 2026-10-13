---
order: 10.1
---

# Button group: Children API

<EuiText>

`EuiButtonGroup` groups related buttons together. There are two APIs: a block with buttons (the children API), or an `@options` array when buttons need radio or checkbox semantics (see the options API below).

Without `@options`, the group yields `Button`, `ButtonEmpty` and `ButtonIcon`: `EuiButton`, `EuiButtonEmpty` and `EuiButtonIcon` wired to the group. They inherit `@buttonSize`, `@isDisabled` and `@hasAriaDisabled` for a cohesive output, and can be wrapped in `EuiToolTip`, `EuiPopover` or `EuiCopy`. Buttons rendered directly (not the yielded ones) are not affected by the group.

**Accessibility recommendation:** the `@legend` argument is required. With a block it is the `aria-label` of the group element (`role="group"`).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiButtonGroup,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormPrepend,
  EuiSelect,
  EuiSpacer,
  EuiSwitch,
  EuiToolTip
} from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked buttonSize = 's';
  @tracked isDisabled = false;
  @tracked isFullWidth = false;

  sizes = [
    { value: 's', text: 's' },
    { value: 'm', text: 'm' }
  ];

  @action
  setSize(event) {
    this.buttonSize = event.target.value;
  }

  @action
  toggle(key) {
    this[key] = !this[key];
  }

  <template>
    <EuiFlexGroup @gutterSize="m" @alignItems="center">
      <EuiFlexItem @grow={{false}}>
        <EuiSelect
          @compressed={{true}}
          @options={{this.sizes}}
          @value={{this.buttonSize}}
          aria-label="Select button size"
          {{on "change" this.setSize}}
        >
          <:prepend><EuiFormPrepend @label="Size" /></:prepend>
        </EuiSelect>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch @compressed={{true}} @label="Disabled" @checked={{this.isDisabled}} @onChange={{fn this.toggle "isDisabled"}} />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch @compressed={{true}} @label="Full width" @checked={{this.isFullWidth}} @onChange={{fn this.toggle "isFullWidth"}} />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiButtonGroup
      @legend="Document actions"
      @buttonSize={{this.buttonSize}}
      @isDisabled={{this.isDisabled}}
      @isFullWidth={{this.isFullWidth}}
      as |group|
    >
      <group.Button @fill={{true}}>Save</group.Button>
      <group.Button @color="text" @iconType="undo" @iconSide="left">Undo</group.Button>
      <group.ButtonEmpty @color="text">Cancel</group.ButtonEmpty>
      <EuiToolTip @content="Delete">
        <group.ButtonIcon @iconType="trash" @color="danger" aria-label="Delete" />
      </EuiToolTip>
    </EuiButtonGroup>
  </template>
}
```
