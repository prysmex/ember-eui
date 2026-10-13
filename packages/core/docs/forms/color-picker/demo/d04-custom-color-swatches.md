---
order: 4
---

# Custom color swatches

<EuiText>

By default the colors provided are the ten color blind safe visualization colors. You can however pass in your own color set with the `@swatches` argument.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiFormRow } from '@ember-eui/core/components';

export default class ColorPickerSwatchesDemo extends Component {
  customSwatches = ['#333', '#666', '#999', '#CCC'];

  @tracked color = '';
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
        @swatches={{this.customSwatches}}
      />
    </EuiFormRow>
  </template>
}
```
