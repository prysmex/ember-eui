---
order: 3
---

# Prepend and append

<EuiText>

Like other form controls, the picker has `<:prepend>` and `<:append>` blocks (upstream's `prepend` and `append` props) for content joined to the control, such as a label or a button. Each block yields the class to put on its content. A palette's own `append` (beside its title in the list, see the previous example) is separate.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPalettePicker, EuiFormPrepend, EuiFormAppend } from '@ember-eui/core/components';

export default class PalettePickerPrependDemo extends Component {
  @tracked selected = 'cool';

  palettes = [
    { value: 'cool', title: 'Cool', type: 'gradient', palette: ['#6092C0', '#A8BFDA', '#D6E6F5'] },
    { value: 'warm', title: 'Warm', type: 'fixed', palette: ['#F5A35C', '#E7664C', '#AA6556'] },
  ];

  @action
  select(value) {
    this.selected = value;
  }

  <template>
    <EuiColorPalettePicker
      @palettes={{this.palettes}}
      @valueOfSelected={{this.selected}}
      @onChange={{this.select}}
    >
      <:prepend><EuiFormPrepend @label="Palette" /></:prepend>
      <:append><EuiFormAppend @iconRight="gear" /></:append>
    </EuiColorPalettePicker>
  </template>
}
```
