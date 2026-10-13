---
order: 1
---

# Radio

<EuiText>

Radios are ideal for allowing users to select options among a small list of options, or to switch settings on/off with an `EuiSwitch`. For longer lists of options, consider using a dropdown selection component.

`EuiRadio` renders a basic HTML `<input type="radio">` element. Use radio buttons to allow users to choose one option out of a list. They are ideal for a list of more than 2 options, and usually no more than 6 options.

When creating a list, each input should have the same `@name` to ensure a group is established. This way when you select a radio button in that group, the other options are automatically deselected.

Make sure to pass a `@label` to ensure a larger clickable area and ensure that screen readers will read out the label when the user is focused on the input.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiRadio, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class RadioDemo extends Component {
  @tracked checked = false;

  @action
  onChange(event) {
    this.checked = event.target.checked;
  }

  <template>
    <EuiRadio
      @label="I am a radio"
      @checked={{this.checked}}
      {{on "change" this.onChange}}
    />

    <EuiSpacer @size="m" />

    <EuiRadio
      @label="I am a disabled radio"
      @checked={{this.checked}}
      @disabled={{true}}
      {{on "change" this.onChange}}
    />

    <EuiSpacer @size="m" />

    <EuiRadio
      @label="I am a compressed radio"
      @checked={{this.checked}}
      @compressed={{true}}
      {{on "change" this.onChange}}
    />
  </template>
}
```
