---
order: 8
---

# Custom SVGs

<EuiText>
  <p>The <EuiCode @language="text">type</EuiCode> prop can accept a valid enum, string or SVG Element. When using a custom SVG, please make sure it sits on a square canvas and preferably utilizes one of EUI's sizes (<EuiCode @language="text">16x16</EuiCode> or <EuiCode @language="text">32x32</EuiCode>).</p>
  <p>When using custom SVGs for simple glyphs, <strong>remove all fill attributes</strong> on the SVG and utilize the CSS helpers if you have complex logos that need to work with theming.</p>
</EuiText>
<EuiSpacer />

```hbs template
<EuiFlexGrid @columns={{2}}>
  <EuiPanel @paddingSize='s'>
    <EuiFlexItem>
      <EuiIcon
        @useSvg={{false}}
        @type='https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg'
        @size='xl'
        @title='My SVG logo'
      />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiCodeBlock @language='html' @fontSize='m' @paddingSize='m'>
        {{this.customsvg}}
      </EuiCodeBlock>
    </EuiFlexItem>
  </EuiPanel>
</EuiFlexGrid>
<EuiSpacer />
<EuiSpacer />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { typeToPathMap } from '@ember-eui/core/utils/css-mappings/eui-icon';

const iconKeys = Object.keys(typeToPathMap);

export default class DemoIconComponent extends Component {
  @tracked customsvg = `
 <EuiIcon @type="https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg" size="xl" title="My SVG logo" />
`;
}
```
