---
order: 10
---

# Toggle button

<EuiText>

Create toggle buttons with `EuiButton`, `EuiButtonEmpty`, or `EuiButtonIcon` using tracked state for visual changes.

If the button's **readable text** (block content or `aria-label`) changes when toggling the button, no additional accessibility concern exists.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { EuiButton, EuiButtonIcon, EuiSpacer, EuiText, EuiToolTip } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked toggle0On = false;
  @tracked toggle1On = true;
  @tracked toggle2On = true;
  @tracked toggle3On = false;

  get playPauseLabel() {
    return this.toggle1On ? 'Play' : 'Pause';
  }

  @action
  toggle(key) {
    this[key] = !this[key];
  }

  <template>
    <EuiButton {{on "click" (fn this.toggle "toggle0On")}}>
      {{if this.toggle0On "Toggled" "Toggle me"}}
    </EuiButton>
    &emsp;
    <EuiToolTip @content={{this.playPauseLabel}} @disableScreenReaderOutput={{true}}>
      <EuiButtonIcon
        @size="s"
        aria-label={{this.playPauseLabel}}
        @iconType={{if this.toggle1On "play" "pause"}}
        {{on "click" (fn this.toggle "toggle1On")}}
      />
    </EuiToolTip>

    <EuiSpacer @size="xl" />

    <EuiText>

    If only the **visual appearance** changes, add `aria-pressed` with a boolean for on/off states. All EUI button types provide an `@isSelected` helper argument for this.

    </EuiText>

    <EuiSpacer />

    <EuiButton
      @isSelected={{this.toggle2On}}
      @fill={{this.toggle2On}}
      @iconType={{if this.toggle2On "starFillSpace" "starPlusEmpty"}}
      {{on "click" (fn this.toggle "toggle2On")}}
    >
      Toggle me
    </EuiButton>
    &emsp;
    <EuiToolTip @content="Autosave" @disableScreenReaderOutput={{true}}>
      <EuiButtonIcon
        @display={{if this.toggle3On "base" "empty"}}
        @size="m"
        aria-label="Autosave"
        @iconType="save"
        @isSelected={{this.toggle3On}}
        @color={{if this.toggle3On "success" "text"}}
        {{on "click" (fn this.toggle "toggle3On")}}
      />
    </EuiToolTip>

    <EuiSpacer />

    <EuiText>

    Do not add `aria-pressed` or `@isSelected` if the readable text changes.

    </EuiText>
  </template>
}
```
