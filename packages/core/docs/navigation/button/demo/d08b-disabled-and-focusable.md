---
order: 8.5
---

# Disabled and focusable (beta)

<EuiText>

By default, `@isDisabled` (or `@disabled`) renders the native `disabled` attribute, which makes the button unfocusable.

For accessibility, you may want a button to appear disabled but remain focusable (e.g. to provide context with a tooltip). Set `@hasAriaDisabled={{true}}` to switch from the native to a custom disabled behavior, which renders a visually identical disabled button that stays focusable. `hasAriaDisabled` is a new, experimental argument; its behavior may change based on feedback and testing.

The key differences of `@hasAriaDisabled`:

- Uses `aria-disabled="true"` instead of the native `disabled` attribute as the semantic state indicator.
- Blocks mouse, pointer, touch, submit and (most) keyboard events, including `click()` and `dispatchEvent()`, to replicate the native disabled behavior.
- Keeps focus events (`focus`, `blur`) and the navigation keys `Tab` and `Escape`.

CSS selectors relying on `:disabled` do not apply: use `[aria-disabled="true"]` instead. Likewise, assert `aria-disabled` rather than `isDisabled()` in tests. `EuiButton`, `EuiButtonEmpty`, `EuiButtonIcon`, `EuiSplitButton` and `EuiButtonGroup` accept `@hasAriaDisabled`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked disableButton = true;

  @action
  toggle() {
    this.disableButton = !this.disableButton;
  }

  <template>
    <EuiSwitch @compressed={{true}} @label="Disabled" @checked={{this.disableButton}} @onChange={{this.toggle}} />
    <EuiSpacer />
    <EuiFlexGroup @responsive={{false}} @gutterSize="s" @alignItems="flexStart">
      <EuiFlexItem @grow={{false}}>
        <EuiButton @disabled={{this.disableButton}} @fill={{true}}>
          {{if this.disableButton "Natively disabled" "Button"}}
        </EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @disabled={{this.disableButton}} @hasAriaDisabled={{true}} @fill={{true}}>
          {{if this.disableButton "Custom disabled" "Button"}}
        </EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
