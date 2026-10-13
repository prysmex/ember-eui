---
order: 2
---

# Color palette display

<EuiText>

Use `EuiColorPaletteDisplay` to show the palette in use for a data visualization.

Use the `@palette` argument to pass your palette as an array of color strings or an array of color stops in the form of `{ stop: number, color: string }`. Use `fixed` palettes for categorical data and `gradient` palettes for continuous data.

In cases you need to apply a palette, it's recommended to use the `EuiColorPalettePicker`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiButtonEmpty,
  EuiCode,
  EuiColorPaletteDisplay,
  EuiColorPalettePicker,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiPopover,
  EuiRange,
  EuiSelect,
  EuiSpacer,
  EuiSwitch,
  EuiTitle,
} from '@ember-eui/core/components';
import {
  euiPaletteColorBlind,
  euiPaletteComplementary,
  euiPaletteCool,
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteGray,
  euiPaletteWarm,
} from '@ember-eui/core/utils/color/eui_palettes';

const paletteWithStops = [
  { stop: 100, color: 'white' },
  { stop: 250, color: 'lightgray' },
  { stop: 320, color: 'gray' },
  { stop: 470, color: 'black' },
];

const paletteData = {
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteComplementary,
  euiPaletteCool,
  euiPaletteWarm,
  euiPaletteGray,
};
const paletteNames = Object.keys(paletteData);

export default class PaletteDisplayDemo extends Component {
  colorBlind = euiPaletteColorBlind();
  paletteWithStops = paletteWithStops;
  sizes = [
    { value: 'xs', text: 'Extra small' },
    { value: 's', text: 'Small' },
    { value: 'm', text: 'Medium' },
  ];

  @tracked palette = '1';
  @tracked categories = 5;
  @tracked selectionType = true;
  @tracked isPopoverOpen = false;
  @tracked size = 's';

  get palettes() {
    return paletteNames.map((paletteName, index) => ({
      value: String(index + 1),
      title: paletteName,
      palette: paletteData[paletteName](this.categories),
      type: this.selectionType ? 'fixed' : 'gradient',
    }));
  }

  get selectedPalette() {
    return paletteData[paletteNames[Number(this.palette) - 1]](this.categories);
  }

  get type() {
    return this.selectionType ? 'fixed' : 'gradient';
  }

  @action
  setPalette(value) {
    this.palette = value;
  }

  @action
  onChangeCategories(event) {
    this.categories = parseInt(event.target.value, 10);
  }

  @action
  onChangeSize(event) {
    this.size = event.target.value;
  }

  @action
  toggleSelectionType() {
    this.selectionType = !this.selectionType;
  }

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  <template>
    <EuiTitle @size="xxxs"><h3>Fixed</h3></EuiTitle>
    <EuiSpacer @size="s" />
    <EuiColorPaletteDisplay @type="fixed" @palette={{this.colorBlind}} />
    <EuiSpacer />
    <EuiTitle @size="xxxs"><h3>Gradient</h3></EuiTitle>
    <EuiSpacer @size="s" />
    <EuiColorPaletteDisplay @type="gradient" @palette={{this.colorBlind}} />
    <EuiSpacer />
    <EuiTitle @size="xxxs"><h3>Fixed with stops</h3></EuiTitle>
    <EuiSpacer @size="s" />
    <EuiColorPaletteDisplay @type="fixed" @palette={{this.paletteWithStops}} />
    <EuiSpacer />
    <EuiTitle @size="xxxs"><h3>Gradient with stops</h3></EuiTitle>
    <EuiSpacer @size="s" />
    <EuiColorPaletteDisplay @type="gradient" @palette={{this.paletteWithStops}} />
    <EuiSpacer />
    <EuiTitle @size="xxxs"><h3>Complex example</h3></EuiTitle>
    <EuiSpacer @size="xs" />
    <EuiFlexGroup @alignItems="center" @gutterSize="xs">
      <EuiFlexItem>
        <EuiColorPaletteDisplay
          @type={{this.type}}
          @palette={{this.selectedPalette}}
          @size={{this.size}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiPopover
          @isOpen={{this.isPopoverOpen}}
          @closePopover={{this.closePopover}}
        >
          <:button>
            <EuiButtonEmpty
              @iconType="controls"
              @color="text"
              @size="xs"
              aria-label="Open settings"
              {{on "click" this.onButtonClick}}
            >
              Customize
            </EuiButtonEmpty>
          </:button>
          <:content>
            <div style="min-width: 380px">
              <EuiFormRow @label="Color palette" @display="columnCompressed">
                <EuiColorPalettePicker
                  @palettes={{this.palettes}}
                  @onChange={{this.setPalette}}
                  @valueOfSelected={{this.palette}}
                  @selectionDisplay="title"
                  @compressed={{true}}
                />
              </EuiFormRow>
              <EuiFormRow @label="Number of stops" @display="columnCompressed">
                <EuiRange
                  @value={{this.categories}}
                  @onChange={{this.onChangeCategories}}
                  @min={{1}}
                  @max={{10}}
                  @compressed={{true}}
                  @showValue={{true}}
                />
              </EuiFormRow>
              <EuiFormRow @label="Size" @display="columnCompressed">
                <EuiSelect
                  @options={{this.sizes}}
                  @value={{this.size}}
                  @compressed={{true}}
                  {{on "change" this.onChangeSize}}
                />
              </EuiFormRow>
              <EuiFormRow @display="columnCompressed">
                <:label>Display <EuiCode>fixed</EuiCode></:label>
                <:field>
                  <EuiSwitch
                    @checked={{this.selectionType}}
                    @onChange={{this.toggleSelectionType}}
                    @compressed={{true}}
                    @showLabel={{false}}
                    @label="Display as fixed"
                  />
                </:field>
              </EuiFormRow>
            </div>
          </:content>
        </EuiPopover>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
