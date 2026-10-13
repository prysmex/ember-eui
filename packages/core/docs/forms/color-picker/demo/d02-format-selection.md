---
order: 2
---

# Format selection

<EuiText>

Format selection does _not_ limit the format of text input the picker will allow, but instead attempts to keep consistency during HSV selection. By default, the color picker will automatically use the last input value format. Notice in the following examples how hue and saturation selection behave differently.

Swatches will always show the "as-authored" color value, as will the value provided via the `@color` argument.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiFormRow } from '@ember-eui/core/components';

export default class ColorPickerFormatDemo extends Component {
  @tracked color = '#D36086';
  @tracked colorErrors = null;

  @action
  setColor(text, { isValid }) {
    this.color = text;
    this.colorErrors = isValid || text === '' ? null : 'Enter a valid color';
  }

  @tracked color2 = '#D36086';
  @tracked color2Errors = null;

  @action
  setColor2(text, { isValid }) {
    this.color2 = text;
    this.color2Errors = isValid || text === '' ? null : 'Enter a valid color';
  }

  @tracked color3 = '211, 96, 134';
  @tracked color3Errors = null;

  @action
  setColor3(text, { isValid }) {
    this.color3 = text;
    this.color3Errors = isValid || text === '' ? null : 'Enter a valid color';
  }

  <template>
    <EuiFormRow
      @label="Auto format"
      @isInvalid={{this.colorErrors}}
      @error={{this.colorErrors}}
    >
      <EuiColorPicker
        @onChange={{this.setColor}}
        @color={{this.color}}
        @isInvalid={{this.colorErrors}}
      />
    </EuiFormRow>
    <EuiFormRow
      @label="Hex format"
      @isInvalid={{this.color2Errors}}
      @error={{this.color2Errors}}
    >
      <EuiColorPicker
        @onChange={{this.setColor2}}
        @color={{this.color2}}
        @isInvalid={{this.color2Errors}}
        @format="hex"
      />
    </EuiFormRow>
    <EuiFormRow
      @label="RGB(a) format"
      @isInvalid={{this.color3Errors}}
      @error={{this.color3Errors}}
    >
      <EuiColorPicker
        @onChange={{this.setColor3}}
        @color={{this.color3}}
        @isInvalid={{this.color3Errors}}
        @format="rgba"
        @showAlpha={{true}}
      />
    </EuiFormRow>
  </template>
}
```
