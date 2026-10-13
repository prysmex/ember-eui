---
order: 3
---

# Alpha channel (opacity) selection

<EuiText>

To allow color opacity via alpha channel, set `@showAlpha={{true}}`. This will also display a range slider allowing manual opacity updates.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiFormRow } from '@ember-eui/core/components';

export default class ColorPickerAlphaDemo extends Component {
  customSwatches = [
    '#54B399',
    '#6092C0',
    '#D36086',
    '#9170B8',
    '#CA8EAE',
    '#54B39940',
    '#6092C040',
    '#D3608640',
    '#9170B840',
    '#CA8EAE40',
  ];

  customSwatches2 = [
    '211, 96, 134, 0.25',
    '211, 96, 134, 0.5',
    '211, 96, 134, 0.75',
    '211, 96, 134',
  ];

  @tracked color = '#D36086';
  @tracked colorErrors = null;

  @action
  setColor(text, { isValid }) {
    this.color = text;
    this.colorErrors = isValid || text === '' ? null : 'Enter a valid color';
  }

  @tracked color2 = '211, 96, 134';
  @tracked color2Errors = null;

  @action
  setColor2(text, { isValid }) {
    this.color2 = text;
    this.color2Errors = isValid || text === '' ? null : 'Enter a valid color';
  }

  <template>
    <EuiFormRow
      @label="Pick a color with optional opacity"
      @isInvalid={{this.colorErrors}}
      @error={{this.colorErrors}}
    >
      <EuiColorPicker
        @onChange={{this.setColor}}
        @color={{this.color}}
        @isInvalid={{this.colorErrors}}
        @showAlpha={{true}}
        @swatches={{this.customSwatches}}
      />
    </EuiFormRow>
    <EuiFormRow
      @label="Using RGBa format"
      @isInvalid={{this.color2Errors}}
      @error={{this.color2Errors}}
    >
      <EuiColorPicker
        @onChange={{this.setColor2}}
        @color={{this.color2}}
        @isInvalid={{this.color2Errors}}
        @showAlpha={{true}}
        @format="rgba"
        @swatches={{this.customSwatches2}}
      />
    </EuiFormRow>
  </template>
}
```
