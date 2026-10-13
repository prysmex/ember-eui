---
order: 1
---

# Color picker

<EuiText>

Color input component allowing for multiple methods of entry and selection.

Direct text entry will match hexadecimal (hex) and RGB(a) colors, and output will return both hex and RGBa values. Spatial selection involves HSV manipulation, which is converted to hex.

Swatches allow consumers to predefine preferred or suggested choices. The swatches must also be entered in hex or RGBa format.

You keep the color: `@onChange` gets the text as typed or picked, and `{ hex, rgba, isValid }`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiFormRow } from '@ember-eui/core/components';

export default class ColorPickerDemo extends Component {
  @tracked color = '#D36086';
  @tracked colorErrors = null;

  @action
  setColor(text, { isValid }) {
    this.color = text;
    this.colorErrors = isValid || text === '' ? null : 'Enter a valid color';
  }

  <template>
    <EuiFormRow
      @label="Pick a color"
      @isInvalid={{this.colorErrors}}
      @error={{this.colorErrors}}
    >
      <EuiColorPicker
        @onChange={{this.setColor}}
        @color={{this.color}}
        @isInvalid={{this.colorErrors}}
      />
    </EuiFormRow>
  </template>
}
```
