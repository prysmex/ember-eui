---
order: 1
---

# Checkbox

<EuiText>

Checkboxes are ideal for allowing users to select options among a small list of options, or to switch settings on/off with an `EuiSwitch`. For longer lists of options, consider using a dropdown selection component.

`EuiCheckbox` renders a basic HTML `<input type="checkbox">` element. Use checkboxes to allow users to select multiple options from a list.

Use the `@checked` argument to handle the checked and unchecked state. You can also use the `@indeterminate` argument to set an indeterminate state. This state is commonly used in hierarchical checkboxes to indicate that only some of the checkbox's descendants are checked.

Use `@readOnly` for a checkbox that shows a state but cannot be changed (it keeps its colours, even on focus). Native `readonly` does not stop checkboxes from toggling, so clicks are cancelled for you.

Make sure to pass a `@label` to ensure a larger clickable area and ensure that screen readers will read out the label when the user is focused on the input.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiCheckbox, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class CheckboxDemo extends Component {
  @tracked checked = false;
  @tracked indeterminate = true;

  @action
  onChange(event) {
    this.checked = event.target.checked;
  }

  @action
  onChangeIndeterminate() {
    this.indeterminate = !this.indeterminate;
  }

  <template>
    <EuiCheckbox
      @label="I am a checkbox"
      @checked={{this.checked}}
      {{on "change" this.onChange}}
    />

    <EuiSpacer @size="m" />

    <EuiCheckbox
      @label="I am an indeterminate checkbox"
      @indeterminate={{this.indeterminate}}
      {{on "change" this.onChangeIndeterminate}}
    />

    <EuiSpacer @size="m" />

    <EuiCheckbox
      @label="I am a disabled checkbox"
      @checked={{this.checked}}
      @disabled={{true}}
      {{on "change" this.onChange}}
    />

    <EuiSpacer @size="m" />

    <EuiCheckbox
      @label="I am a readonly checkbox"
      @checked={{this.checked}}
      @readOnly={{true}}
    />
  </template>
}
```
