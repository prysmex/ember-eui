---
order: 7
---

# Colors

<EuiText>
 <p>The default behavior of icons is to inherit from the text color. You can use the <EuiCode @language="text">color</EuiCode> prop to assign a custom color which accepts a named color from our palette or a valid&nbsp;<a class="euiLink euiLink--primary" href="https://developer.mozilla.org/en-US/docs/Web/CSS/color_value" target="_blank" rel="noopener noreferrer">CSS color data type<<span class="euiScreenReaderOnly">(opens in a new tab or window)</span></a>&nbsp;which will be passed down through the inline-style <EuiCode @language="text">fill</EuiCode>&nbsp; property. <strong>We recommend relying on the EUI named color palette</strong> unless the custom color is initiated by the user (like as a graph color).</p>
</EuiText>

```hbs template
<EuiCodeBlock @language='html' @fontSize='m' @paddingSize='m'>
  {{this.colorCode}}
</EuiCodeBlock>
<EuiSpacer />
<EuiFlexGrid @columns={{3}}>
  {{#each this.iconColors as |color|}}
    <EuiFlexItem>
      <EuiCopy
        @textToCopy={{color}}
        @beforeMessage='Click to Copy'
        @afterMessage='Copied'
        as |copy|
      >
        <EuiPanel
          @paddingSize='s'
          {{on 'click' copy}}
          @hasShadow={{false}}
          @isClickable={{true}}
        >
          <EuiIcon @type='brush' @color={{color}} />
          <small>
            {{color}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
<EuiSpacer />
<EuiText>
  <p>Two-tone icons, like our app style icons, will behave similarly to normal
    glyphs when provided a specific color by applying the color to
    <strong>all</strong>
    the shapes within. You can force the icon to match the parent's text color
    by passing
    <EuiCode @language='text'>color="inherit"</EuiCode>
    to the icon.</p>
</EuiText>
<EuiSpacer />
<EuiCodeBlock @language='html' @fontSize='m' @paddingSize='m'>
  {{this.colorinherit}}
</EuiCodeBlock>
<EuiSpacer />
<EuiFlexGrid @columns={{3}}>
  {{#each this.iconColors as |color|}}
    <EuiFlexItem>
      <EuiCopy
        @textToCopy={{color}}
        @beforeMessage='Click to Copy'
        @afterMessage='Copied'
        as |copy|
      >
        <EuiPanel
          @paddingSize='s'
          {{on 'click' copy}}
          @hasShadow={{false}}
          @isClickable={{true}}
        >
          <EuiIcon @type='gisApp' @color={{color}} />
          <small>
            {{color}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { typeToPathMap } from '@ember-eui/core/utils/css-mappings/eui-icon';

const iconKeys = Object.keys(typeToPathMap);

export default class DemoIconComponent extends Component {
  @tracked colorCode = `
 <EuiIcon type="brush" color="primary" />
`;

  @tracked colorinherit = `
 <EuiIcon type="gisApp" color="primary" />
`;

  @tracked iconColors = [
    'default',
    'inherit',
    'primary',
    'success',
    'accent',
    'warning',
    'danger',
    'text',
    'subdued',
    'ghost',
    '#DA8B45',
    '#DDDDDD'
  ];
}
```
