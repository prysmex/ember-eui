---
order: 1
---

# Palette picker

<EuiText>

Fixed and gradient palettes, and a text-only option. `@selectionDisplay`
shows the selected palette as colors (default) or by its title.

</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiFormRow @label="Color palette">
      <EuiColorPalettePicker
        @palettes={{this.palettes}}
        @valueOfSelected={{this.palette}}
        @onChange={{this.setPalette}}
      />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="By title">
      <EuiColorPalettePicker
        @palettes={{this.palettes}}
        @valueOfSelected={{this.palette}}
        @onChange={{this.setPalette}}
        @selectionDisplay="title"
      />
    </EuiFormRow>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PalettePickerDemo extends Component {
  @tracked palette = 'blind';

  palettes = [
    {
      value: 'blind',
      title: 'Color blind safe',
      type: 'fixed',
      palette: ['#54B399', '#6092C0', '#D36086', '#9170B8', '#CA8EAE', '#D6BF57', '#B9A888'],
    },
    {
      value: 'status',
      title: 'Status',
      type: 'gradient',
      palette: ['#209280', '#54B399', '#D6BF57', '#E7664C', '#CC5642'],
    },
    {
      value: 'temperature',
      title: 'Temperature (stops)',
      type: 'gradient',
      palette: [
        { stop: 0, color: '#6092C0' },
        { stop: 60, color: '#EBEFF5' },
        { stop: 100, color: '#E7664C' },
      ],
    },
    { value: 'custom', title: 'Custom', type: 'text' },
  ];

  @action
  setPalette(value) {
    this.palette = value;
  }
}
```
