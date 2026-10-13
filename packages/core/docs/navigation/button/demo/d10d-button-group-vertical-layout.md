---
order: 10.4
---

# Button group: Vertical layout

<EuiText>

Use `@layout="vertical"` to stack the buttons of a segmented (or selection) group in a column instead of a row. This layout should only be used with `ButtonIcon` children.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
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
  toggleDividers() {
    this.showDividers = !this.showDividers;
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
        <EuiSwitch @compressed={{true}} @label="Show dividers" @checked={{this.showDividers}} @onChange={{this.toggleDividers}} />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiButtonGroup
      @legend="Icon actions"
      @variant="segmented"
      @layout="vertical"
      @buttonSize={{this.buttonSize}}
      @showDividers={{this.showDividers}}
      as |group|
    >
      {{#each this.actions as |item|}}
        <EuiToolTip @content={{item.label}} @position="right">
          <group.ButtonIcon @iconType={{item.iconType}} aria-label={{item.label}} />
        </EuiToolTip>
      {{/each}}
    </EuiButtonGroup>
  </template>
}
```
