---
order: 2
---

# Modes, custom swatches and a custom button

<EuiText>

`@mode="swatch"` with your own `@swatches`, `@mode="picker"` without
swatches, and a trigger rendered by the `<:button>` block.

</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiFormRow @label="Swatches only">
      <EuiColorPicker
        @mode="swatch"
        @swatches={{this.brandColors}}
        @color={{this.swatchColor}}
        @onChange={{this.setSwatchColor}}
      />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Picker only">
      <EuiColorPicker
        @mode="picker"
        @color={{this.pickerColor}}
        @onChange={{this.setPickerColor}}
      />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Custom button">
      <EuiColorPicker @color={{this.buttonColor}} @onChange={{this.setButtonColor}}>
        <:button as |toggle|>
          <EuiColorPickerSwatch
            @color={{this.buttonColor}}
            aria-label="Choose the highlight color"
            {{on "click" toggle}}
          />
        </:button>
      </EuiColorPicker>
    </EuiFormRow>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ColorPickerModes extends Component {
  brandColors = ['#0B64DD', '#008B87', '#E7664C', '#F5A700', '#343741'];

  @tracked swatchColor = '#008B87';
  @tracked pickerColor = '#6092C0';
  @tracked buttonColor = '#F5A700';

  @action
  setSwatchColor(text) {
    this.swatchColor = text;
  }

  @action
  setPickerColor(text) {
    this.pickerColor = text;
  }

  @action
  setButtonColor(text) {
    this.buttonColor = text;
  }
}
```
