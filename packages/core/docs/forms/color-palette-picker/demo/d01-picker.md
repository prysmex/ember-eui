---
order: 1
---

# Color palette picker

<EuiText>

Use `EuiColorPalettePicker` to select palettes to apply colors to data visualization like maps and charts.

Use the `@palettes` argument to pass your palettes as an array of strings or an array of color stops in the form of `{ stop: number, color: string }`. For each object, you should pass a palette (array of hex values) and specify the `type`. Use `fixed` palettes for categorical data and `gradient` palettes for continuous data.

Each of the `@palettes`, excluding `type: 'text'` palettes, can use `append` to add something to the right of its title in the list: text, or a component (the Ember counterpart of upstream's element).

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
  EuiText,
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

// Appended content can be a component, e.g. subdued text
const labelled = (label) =>
  <template>
    <EuiText @color="subdued" @size="xs"><span>{{label}}</span></EuiText>
  </template>;

const FIXED = labelled('fixed');
const GRADIENT = labelled('gradient');
const GRADIENT_STOPS = labelled('gradient with stops');
const FIXED_STOPS = labelled('fixed with stops');

export default class PalettePickerDemo extends Component {
  toggles = [
    { key: 'selectionDisplay', label: 'Display selected item as a title' },
    { key: 'append', label: 'Display append element on title' },
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'disabled', label: 'disabled' },
  ];

  get palettes() {
    const append = this.flags.append;

    return [
    {
      value: 'palette_1',
      title: 'EUI color blind',
      palette: euiPaletteColorBlind(),
      append: append && FIXED,
      type: 'fixed',
    },
    {
      value: 'palette_2',
      title: 'EUI palette for status',
      palette: euiPaletteForStatus(5),
      append: append && GRADIENT,
      type: 'gradient',
    },
    {
      value: 'palette_3',
      title: 'EUI palette for temperature',
      palette: euiPaletteForTemperature(5),
      append: append && FIXED,
      type: 'fixed',
    },
    {
      value: 'palette_4',
      title: 'Grayscale',
      palette: stops,
      append: append && GRADIENT_STOPS,
      type: 'gradient',
    },
    {
      value: 'palette_5',
      title: 'Grayscale',
      palette: stops,
      append: append && FIXED_STOPS,
      type: 'fixed',
    },
    {
      value: 'custom',
      title: 'Plain text as a custom option',
      type: 'text',
    },
    ];
  }

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
