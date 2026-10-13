---
order: 7
---

# Empty state

<EuiText>

For instances where an "empty" color picker has meaning other than transparent color value, use the `@placeholder` argument to provide context. Removing color selection and returning to the default state can be made easier by setting `@isClearable={{true}}`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiFormRow } from '@ember-eui/core/components';

export default class ColorPickerEmptyDemo extends Component {
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
        @placeholder="Auto"
        @isClearable={{true}}
      />
    </EuiFormRow>
  </template>
}
```
