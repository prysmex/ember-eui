---
order: 1
---

# Labels, icons and buttons

<EuiText>

A static node renders `@label` as a `<label>` pointing to the field, so
clicking it focuses the input. With `@onClick` it becomes a button; the
label is then the button text.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { EuiFieldText, EuiFormPrepend, EuiSpacer, EuiFieldNumber, EuiFormAppend } from '@ember-eui/core/components';

export default class AppendPrependDemo extends Component {
  @action
  toggle() {
    // open a popover, a menu, …
  }

  <template>
    <EuiFieldText @placeholder="Username" aria-label="Username">
      <:prepend>
        <EuiFormPrepend @label="User" @iconLeft="user" />
      </:prepend>
    </EuiFieldText>
    <EuiSpacer />
    <EuiFieldNumber placeholder="0" aria-label="Amount">
      <:prepend>
        <EuiFormPrepend @iconLeft="money" />
      </:prepend>
      <:append>
        <EuiFormAppend @label="USD" />
      </:append>
    </EuiFieldNumber>
    <EuiSpacer />
    <EuiFieldText @placeholder="Search" aria-label="Search" @compressed={{true}}>
      <:append>
        <EuiFormAppend
          @label="Options"
          @iconRight="arrowDown"
          @onClick={{this.toggle}}
        />
      </:append>
    </EuiFieldText>
    <EuiSpacer />
    <EuiFieldText
      @placeholder="Disabled"
      aria-label="Disabled field"
      @disabled={{true}}
    >
      <:prepend>
        <EuiFormPrepend @label="Disabled" />
      </:prepend>
    </EuiFieldText>
  </template>
}
```
