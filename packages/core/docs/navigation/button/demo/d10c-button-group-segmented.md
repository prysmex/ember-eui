---
order: 10.3
---

# Button group: Segmented

<EuiText>

Use `@variant="segmented"` for a visually unified row where all buttons are treated as a single connected control. The buttons sit flush against each other with no gap, rendering the group as one cohesive element.

Unlike the default variant, segmented groups have two constraints:

- Only `Button` or `ButtonIcon` are accepted; `ButtonEmpty` is not supported.
- All children must be the **same button type**: either all `Button` or all `ButtonIcon`, not a mix of both.

Add `@showDividers={{true}}` to render a separator line between buttons. By default the segmented group wraps depending on the available space; use `@wrap={{false}}` to prevent wrapping.

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

const ACTIONS = [
  { label: 'Delete', iconType: 'trash' },
  { label: 'Rename', iconType: 'pencil' },
  { label: 'Disable', iconType: 'pause' },
  { label: 'Duplicate', iconType: 'copy' },
  { label: 'Save', iconType: 'save' }
];

export default class DemoComponent extends Component {
  @tracked buttonSize = 's';
  @tracked showDividers = false;
  @tracked isFullWidth = false;
  @tracked wrap = true;

  actions = ACTIONS;
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
    <EuiFlexGroup @gutterSize="m" @alignItems="center" @wrap={{true}}>
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
        <EuiSwitch @compressed={{true}} @label="Show dividers" @checked={{this.showDividers}} @onChange={{fn this.toggle "showDividers"}} />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch @compressed={{true}} @label="Full width" @checked={{this.isFullWidth}} @onChange={{fn this.toggle "isFullWidth"}} />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch @compressed={{true}} @label="Wrap" @checked={{this.wrap}} @onChange={{fn this.toggle "wrap"}} />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiFlexGroup @direction="column" @gutterSize="s">
      <EuiFlexItem @grow={{this.isFullWidth}}>
        <EuiButtonGroup
          @legend="Document actions"
          @variant="segmented"
          @buttonSize={{this.buttonSize}}
          @showDividers={{this.showDividers}}
          @isFullWidth={{this.isFullWidth}}
          @wrap={{this.wrap}}
          as |group|
        >
          {{#each this.actions as |item|}}
            <group.Button>{{item.label}}</group.Button>
          {{/each}}
        </EuiButtonGroup>
      </EuiFlexItem>
      <EuiFlexItem @grow={{this.isFullWidth}}>
        <EuiButtonGroup
          @legend="Icon actions"
          @variant="segmented"
          @buttonSize={{this.buttonSize}}
          @showDividers={{this.showDividers}}
          @isFullWidth={{this.isFullWidth}}
          @wrap={{this.wrap}}
          as |group|
        >
          {{#each this.actions as |item|}}
            <EuiToolTip @content={{item.label}}>
              <group.ButtonIcon @iconType={{item.iconType}} aria-label={{item.label}} />
            </EuiToolTip>
          {{/each}}
        </EuiButtonGroup>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
