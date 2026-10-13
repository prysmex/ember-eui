---
order: 1
---

# Preset qualitative palettes

```gjs component
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import {
  EuiBadge,
  EuiCode,
  EuiCopy,
  EuiFlexGrid,
  EuiFlexGroup,
  EuiFlexItem,
  EuiLink,
  EuiSpacer,
  EuiTitle
} from '@ember-eui/core/components';
import { getEuiThemeContext } from '@ember-eui/core/theming';
import {
  useEuiPaletteColorBlind,
  useEuiPaletteColorBlindBehindText
} from '@ember-eui/core/utils/color';

export default class QualitativePalettesDemo extends Component {
  // Theme-aware: recomputed when the color mode or high contrast changes.
  @cached
  get palettes() {
    const context = getEuiThemeContext(this).upstream;

    return [
      {
        title: 'Max 10 colors',
        palette: useEuiPaletteColorBlind(context),
        code: 'useEuiPaletteColorBlind(context)'
      },
      {
        title: 'More than 10 colors are needed',
        palette: useEuiPaletteColorBlind(context, { rotations: 2 }),
        code: 'useEuiPaletteColorBlind(context, { rotations: 2 })'
      },
      {
        title: 'Series may have multiple metrics and so the colors must coordinate but be distinguishable',
        palette: useEuiPaletteColorBlind(context, { rotations: 3, order: 'group', direction: 'both' }),
        code: "useEuiPaletteColorBlind(context, { rotations: 3, order: 'group', direction: 'both' })"
      },
      {
        title: "The default sort order is close but not exactly aligned with the color wheel. To sort this better add the 'natural' sort param.",
        palette: useEuiPaletteColorBlind(context, { sortBy: 'natural' }),
        code: "useEuiPaletteColorBlind(context, { sortBy: 'natural' })"
      }
    ];
  }

  @cached
  get behindText() {
    return useEuiPaletteColorBlindBehindText(getEuiThemeContext(this).upstream, { sortBy: 'natural' });
  }

  swatch = (hex) => htmlSafe(`background-color: ${hex}; block-size: 16px; inline-size: 32px;`);

  <template>
    <div>
      {{#each this.palettes as |palette|}}
        <EuiTitle @size='xxs'><h3>{{palette.title}}</h3></EuiTitle>
        <EuiSpacer @size='s' />
        <EuiFlexGroup @alignItems='center'>
          <EuiFlexItem @grow={{false}} style='max-inline-size: 240px'>
            <EuiFlexGroup @gutterSize='none' @alignItems='flexStart' @responsive={{false}} @wrap={{true}} style='border-radius: 6px; overflow: hidden'>
              {{#each palette.palette as |hex|}}
                <EuiFlexItem @grow={{false}}><span title={{hex}} style={{this.swatch hex}}></span></EuiFlexItem>
              {{/each}}
            </EuiFlexGroup>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiCopy @beforeMessage='Click to copy palette config' @textToCopy={{palette.code}} as |copy|>
              <EuiLink {{on 'click' copy}}><EuiCode>{{palette.code}}</EuiCode></EuiLink>
            </EuiCopy>
          </EuiFlexItem>
        </EuiFlexGroup>
        <EuiSpacer @size='xl' />
      {{/each}}

      <EuiTitle @size='xxs'><h3>Behind text variant</h3></EuiTitle>
      <EuiSpacer @size='s' />
      <EuiFlexGroup @alignItems='center'>
        <EuiFlexItem @grow={{false}} style='max-inline-size: 240px'>
          <EuiFlexGrid @columns={{4}} @gutterSize='s'>
            {{#each this.behindText as |color|}}
              <EuiFlexItem @grow={{false}}><span><EuiBadge @color={{color}}>Text</EuiBadge></span></EuiFlexItem>
            {{/each}}
          </EuiFlexGrid>
        </EuiFlexItem>
        <EuiFlexItem>
          <EuiCode>useEuiPaletteColorBlindBehindText(context, { sortBy: 'natural' })</EuiCode>
        </EuiFlexItem>
      </EuiFlexGroup>
    </div>
  </template>
}
```
