---
order: 10.2
---

# Button group: Gutter size

<EuiText>

Control the gap between the buttons with `@gutterSize` (block with the default variant only). The default is `"s"`; use `"none"` to remove the gap entirely.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButtonGroup, EuiFormPrepend, EuiSelect, EuiSpacer, EuiToolTip } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked gutterSize = 's';

  gutterSizes = ['none', 'xs', 's', 'm', 'l', 'xl'].map((size) => ({ value: size, text: size }));

  @action
  setGutterSize(event) {
    this.gutterSize = event.target.value;
  }

  <template>
    <div style="max-width: 240px">
      <EuiSelect
        @compressed={{true}}
        @options={{this.gutterSizes}}
        @value={{this.gutterSize}}
        aria-label="Select gutterSize"
        {{on "change" this.setGutterSize}}
      >
        <:prepend><EuiFormPrepend @label="gutterSize" /></:prepend>
      </EuiSelect>
    </div>
    <EuiSpacer @size="m" />
    <EuiButtonGroup @legend="Actions" @gutterSize={{this.gutterSize}} as |group|>
      <group.Button>Save</group.Button>
      <group.ButtonEmpty @color="text">Cancel</group.ButtonEmpty>
      <EuiToolTip @content="Delete">
        <group.ButtonIcon @iconType="trash" @color="danger" aria-label="Delete" />
      </EuiToolTip>
    </EuiButtonGroup>
  </template>
}
```
