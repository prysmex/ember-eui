---
order: 5
---

# Limited selection modes

<EuiText>

By default, both swatch selection and the gradient color map will be rendered. Use the `@mode` argument to pass `swatch` for swatch-only selection, or pass `picker` for gradient map and hue slider selection without swatches.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiFormRow } from '@ember-eui/core/components';

export default class ColorPickerModesDemo extends Component {
  @tracked color = '#D36086';
  @tracked colorErrors = null;

  @action
  setColor(text, { isValid }) {
    this.color = text;
    this.colorErrors = isValid || text === '' ? null : 'Enter a valid color';
  }

  <template>
    <EuiFormRow
      @label="Pick a swatch"
      @isInvalid={{this.colorErrors}}
      @error={{this.colorErrors}}
    >
      <EuiColorPicker
        @onChange={{this.setColor}}
        @color={{this.color}}
        @isInvalid={{this.colorErrors}}
        @mode="swatch"
      />
    </EuiFormRow>
    <EuiFormRow
      @label="Pick a color"
      @isInvalid={{this.colorErrors}}
      @error={{this.colorErrors}}
    >
      <EuiColorPicker
        @onChange={{this.setColor}}
        @color={{this.color}}
        @isInvalid={{this.colorErrors}}
        @mode="picker"
      />
    </EuiFormRow>
  </template>
}
```
