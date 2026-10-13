---
order: 3
---

# Custom palettes

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
import { colorPalette, useEuiPaletteColorBlind } from '@ember-eui/core/utils/color';

export default class CustomPalettesDemo extends Component {
  @tracked length = 10;

  @cached
  get rows() {
    const vis = useEuiPaletteColorBlind(getEuiThemeContext(this).upstream);
    const steps = Number(this.length);
    const palettes = [[vis[3]], [vis[3], vis[4]], [vis[3], vis[4]]];

    return palettes.map((palette, i) => {
      const diverging = i > 1;

      return {
        palette: colorPalette(palette, steps, diverging),
        code: `colorPalette([${palette}], ${steps}${diverging ? ', true' : ''});`
      };
    });
  }

  @action
  onLengthChange(event) {
    this.length = event.target.value;
  }

  swatch = (hex) => htmlSafe(`background-color: ${hex}; block-size: 16px; inline-size: 32px;`);

  <template>
    <div>
      <EuiFormRow @label='Number of steps' @display='columnCompressed'>
        <EuiRange @min={{2}} @max={{20}} @compressed={{true}} @showValue={{true}} @value={{this.length}} @onChange={{this.onLengthChange}} />
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
            <EuiCopy @beforeMessage='Click to copy palette config' @textToCopy={{row.code}} as |copy|>
              <EuiLink {{on 'click' copy}}><EuiCode>{{row.code}}</EuiCode></EuiLink>
            </EuiCopy>
          </EuiFlexItem>
        </EuiFlexGroup>
      {{/each}}
    </div>
  </template>
}
```
