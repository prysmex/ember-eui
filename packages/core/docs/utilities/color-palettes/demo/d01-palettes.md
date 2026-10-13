---
order: 1
---

# Palettes

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';
import {
  EuiCode,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiRange,
  EuiSpacer,
  EuiTitle
} from '@ember-eui/core/components';
import {
  colorPalette,
  euiPaletteColorBlind,
  euiPaletteColorBlindBehindText,
  euiPaletteCool,
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteGray,
  euiPaletteWarm
} from '@ember-eui/core/utils/color';

const quantitative = {
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteCool,
  euiPaletteWarm,
  euiPaletteGray
};

export default class PalettesDemo extends Component {
  @tracked length = 5;

  qualitative = [
    { code: 'euiPaletteColorBlind()', palette: euiPaletteColorBlind() },
    { code: 'euiPaletteColorBlind({ rotations: 2 })', palette: euiPaletteColorBlind({ rotations: 2 }) },
    {
      code: "euiPaletteColorBlind({ rotations: 3, order: 'group', direction: 'both' })",
      palette: euiPaletteColorBlind({ rotations: 3, order: 'group', direction: 'both' })
    },
    { code: "euiPaletteColorBlind({ sortBy: 'natural' })", palette: euiPaletteColorBlind({ sortBy: 'natural' }) },
    { code: "euiPaletteColorBlindBehindText({ sortBy: 'natural' })", palette: euiPaletteColorBlindBehindText({ sortBy: 'natural' }) }
  ];

  get quantitativeRows() {
    const steps = Number(this.length);
    return Object.entries(quantitative).map(([name, fn]) => ({
      code: `${name}(${steps})`,
      palette: fn(steps)
    }));
  }

  get custom() {
    const steps = Number(this.length);
    const [a, b] = euiPaletteColorBlind().slice(3, 5);
    return [
      { code: `colorPalette(['${a}'], ${steps})`, palette: colorPalette([a], steps) },
      { code: `colorPalette(['${a}', '${b}'], ${steps}, true)`, palette: colorPalette([a, b], steps, true) }
    ];
  }

  @action
  onLengthChange(event) {
    this.length = event.target.value;
  }

  swatch = (hex) => htmlSafe(`background-color: ${hex}; block-size: 32px; inline-size: 32px;`);

  <template>
    <div>
      <EuiTitle @size='xs'><h3>Qualitative</h3></EuiTitle>
      <EuiSpacer @size='s' />
      {{#each this.qualitative as |row|}}
        <EuiFlexGroup @alignItems='center' @gutterSize='m'>
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup @gutterSize='none' @responsive={{false}} @wrap={{true}} style='max-inline-size: 320px'>
              {{#each row.palette as |hex|}}
                <div style={{this.swatch hex}} title={{hex}}></div>
              {{/each}}
            </EuiFlexGroup>
          </EuiFlexItem>
          <EuiFlexItem><EuiCode>{{row.code}}</EuiCode></EuiFlexItem>
        </EuiFlexGroup>
        <EuiSpacer @size='m' />
      {{/each}}

      <EuiTitle @size='xs'><h3>Quantitative and custom</h3></EuiTitle>
      <EuiSpacer @size='s' />
      <EuiFormRow @label='Number of steps' @display='columnCompressed'>
        <EuiRange @min={{2}} @max={{20}} @compressed={{true}} @showValue={{true}} @value={{this.length}} @onChange={{this.onLengthChange}} />
      </EuiFormRow>
      <EuiSpacer />
      {{#each this.quantitativeRows as |row|}}
        <EuiFlexGroup @alignItems='center' @gutterSize='m'>
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup @gutterSize='none' @responsive={{false}}>
              {{#each row.palette as |hex|}}
                <div style={{this.swatch hex}} title={{hex}}></div>
              {{/each}}
            </EuiFlexGroup>
          </EuiFlexItem>
          <EuiFlexItem><EuiCode>{{row.code}}</EuiCode></EuiFlexItem>
        </EuiFlexGroup>
        <EuiSpacer @size='s' />
      {{/each}}
      {{#each this.custom as |row|}}
        <EuiFlexGroup @alignItems='center' @gutterSize='m'>
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup @gutterSize='none' @responsive={{false}}>
              {{#each row.palette as |hex|}}
                <div style={{this.swatch hex}} title={{hex}}></div>
              {{/each}}
            </EuiFlexGroup>
          </EuiFlexItem>
          <EuiFlexItem><EuiCode>{{row.code}}</EuiCode></EuiFlexItem>
        </EuiFlexGroup>
        <EuiSpacer @size='s' />
      {{/each}}
    </div>
  </template>
}
```
