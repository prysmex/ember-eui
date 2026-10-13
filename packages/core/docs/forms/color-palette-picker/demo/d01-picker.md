---
order: 1
---

# Color palette picker

<EuiText>

Use `EuiColorPalettePicker` to select palettes to apply colors to data visualization like maps and charts.

Use the `@palettes` argument to pass your palettes as an array of strings or an array of color stops in the form of `{ stop: number, color: string }`. For each object, you should pass a palette (array of hex values) and specify the `type`. Use `fixed` palettes for categorical data and `gradient` palettes for continuous data.

The switch above the picker and the toggles are docs-only helpers.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get } from '@ember/helper';
import {
  EuiColorPalettePicker,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';
import {
  euiPaletteColorBlind,
  euiPaletteForStatus,
  euiPaletteForTemperature,
} from '@ember-eui/core/utils/color/eui_palettes';

const stops = [
  { stop: 100, color: 'white' },
  { stop: 250, color: 'lightgray' },
  { stop: 320, color: 'gray' },
  { stop: 470, color: 'black' },
];

export default class PalettePickerDemo extends Component {
  toggles = [
    { key: 'selectionDisplay', label: 'Display selected item as a title' },
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'disabled', label: 'disabled' },
  ];

  palettes = [
    {
      value: 'palette_1',
      title: 'EUI color blind',
      palette: euiPaletteColorBlind(),
      type: 'fixed',
    },
    {
      value: 'palette_2',
      title: 'EUI palette for status',
      palette: euiPaletteForStatus(5),
      type: 'gradient',
    },
    {
      value: 'palette_3',
      title: 'EUI palette for temperature',
      palette: euiPaletteForTemperature(5),
      type: 'fixed',
    },
    {
      value: 'palette_4',
      title: 'Grayscale',
      palette: stops,
      type: 'gradient',
    },
    {
      value: 'palette_5',
      title: 'Grayscale',
      palette: stops,
      type: 'fixed',
    },
    {
      value: 'custom',
      title: 'Plain text as a custom option',
      type: 'text',
    },
  ];

  @tracked flags = {};
  @tracked selectedPalette = 'palette_1';

  get selectionDisplay() {
    return this.flags.selectionDisplay ? 'title' : 'palette';
  }

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  setPalette(value) {
    this.selectedPalette = value;
  }

  <template>
    <EuiFlexGroup @wrap={{true}} @gutterSize="m" @responsive={{false}}>
      {{#each this.toggles as |toggle|}}
        <EuiFlexItem @grow={{false}}>
          <EuiSwitch
            @label={{toggle.label}}
            @compressed={{true}}
            @checked={{get this.flags toggle.key}}
            @onChange={{fn this.toggle toggle.key}}
          />
        </EuiFlexItem>
      {{/each}}
    </EuiFlexGroup>
    <EuiSpacer @size="m" />
    <EuiColorPalettePicker
      @palettes={{this.palettes}}
      @onChange={{this.setPalette}}
      @valueOfSelected={{this.selectedPalette}}
      @selectionDisplay={{this.selectionDisplay}}
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @disabled={{this.flags.disabled}}
    />
  </template>
}
```
