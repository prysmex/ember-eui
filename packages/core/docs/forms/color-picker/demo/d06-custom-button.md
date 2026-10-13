---
order: 6
---

# Custom button

<EuiText>

Available only in `EuiColorPicker`. You can optionally use a custom button as the trigger for selection with the `<:button>` block, which yields the function that toggles the popover. Please remember to add accessibility to this component, using proper button markup and aria labeling.

Additionally, use the `@secondaryInputDisplay` argument to show a secondary or alternative color value input. Options include `top` and `bottom` placement.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiFormRow, EuiColorPickerSwatch, EuiBadge, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class ColorPickerButtonDemo extends Component {
  @tracked color = '';
  @tracked selectedColor = '';
  @tracked errors = null;

  @action
  handleColorChange(text, { hex, isValid }) {
    this.color = text;
    this.errors = isValid || text === '' ? null : 'Enter a valid color';
    this.selectedColor = hex;
  }

  <template>
    <EuiFormRow @label="Pick a color" @error={{this.errors}}>
      <EuiColorPicker
        @onChange={{this.handleColorChange}}
        @color={{this.color}}
        @secondaryInputDisplay="top"
        @isClearable={{true}}
      >
        <:button as |toggle|>
          <EuiColorPickerSwatch
            @color={{this.selectedColor}}
            aria-label="Select a new color"
            {{on "click" toggle}}
          />
        </:button>
      </EuiColorPicker>
    </EuiFormRow>
    <EuiSpacer />
    <EuiColorPicker
      @onChange={{this.handleColorChange}}
      @color={{this.color}}
      @isInvalid={{this.errors}}
      @secondaryInputDisplay="bottom"
    >
      <:button as |toggle|>
        <EuiBadge
          @color={{if this.selectedColor this.selectedColor "hollow"}}
          @onClick={{toggle}}
          @onClickAriaLabel="Select a new color"
        >
          Color this badge
        </EuiBadge>
      </:button>
    </EuiColorPicker>
  </template>
}
```
