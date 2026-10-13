---
order: 2
---

# Recommended quantitative palettes

```gjs component
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import {
  EuiCode,
  EuiCopy,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiLink,
  EuiRange,
  EuiSpacer
} from '@ember-eui/core/components';
import { getEuiThemeContext } from '@ember-eui/core/theming';
import {
  useEuiPaletteComplementary,
  useEuiPaletteCool,
  useEuiPaletteForStatus,
  useEuiPaletteForTemperature,
  useEuiPaletteGray,
  useEuiPaletteGreen,
  useEuiPaletteOrange,
  useEuiPaletteRed,
  useEuiPaletteSkyBlue,
  useEuiPaletteWarm,
  useEuiPaletteYellow
} from '@ember-eui/core/utils/color';

const paletteData = {
  euiPaletteForStatus: useEuiPaletteForStatus,
  euiPaletteForTemperature: useEuiPaletteForTemperature,
  euiPaletteComplementary: useEuiPaletteComplementary,
  euiPaletteRed: useEuiPaletteRed,
  euiPaletteGreen: useEuiPaletteGreen,
  euiPaletteSkyBlue: useEuiPaletteSkyBlue,
  euiPaletteYellow: useEuiPaletteYellow,
  euiPaletteOrange: useEuiPaletteOrange,
  euiPaletteCool: useEuiPaletteCool,
  euiPaletteWarm: useEuiPaletteWarm,
  euiPaletteGray: useEuiPaletteGray
};

export default class QuantitativePalettesDemo extends Component {
  @tracked length = 5;

  @cached
  get rows() {
    const context = getEuiThemeContext(this).upstream;
    const steps = Number(this.length);

    return Object.entries(paletteData).map(([name, palette]) => ({
      code: `${name}(${steps})`,
      copy: `${name}(${steps});`,
      palette: palette(context, steps)
    }));
  }

  @action
  onLengthChange(event) {
    this.length = event.target.value;
  }

  swatch = (hex) => htmlSafe(`background-color: ${hex}; block-size: 16px; inline-size: 32px;`);

  <template>
    <div>
      <EuiFormRow @label='Number of steps' @display='columnCompressed'>
        <EuiRange @min={{1}} @max={{20}} @compressed={{true}} @showValue={{true}} @value={{this.length}} @onChange={{this.onLengthChange}} />
      </EuiFormRow>
      <EuiSpacer />
      {{#each this.rows as |row|}}
        <EuiFlexGroup @alignItems='center'>
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup @gutterSize='none' @responsive={{false}} style='border-radius: 6px; overflow: hidden'>
              {{#each row.palette as |hex|}}
                <EuiFlexItem @grow={{false}}><span title={{hex}} style={{this.swatch hex}}></span></EuiFlexItem>
              {{/each}}
            </EuiFlexGroup>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiCopy @beforeMessage='Click to copy palette config' @textToCopy={{row.copy}} as |copy|>
              <EuiLink {{on 'click' copy}}><EuiCode>{{row.code}}</EuiCode></EuiLink>
            </EuiCopy>
          </EuiFlexItem>
        </EuiFlexGroup>
      {{/each}}
    </div>
  </template>
}
```
