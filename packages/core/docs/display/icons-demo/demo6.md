---
order: 6
---

# Sizes

<EuiText>
  <p>Use the <EuiCode @language="text">size</EuiCode> prop to automatically size your icons. Medium is the default, and will output a <EuiCode @language="text">16x16</EuiCode> icon.</p>
</EuiText>

```hbs template
<EuiCodeBlock @language='html' @fontSize='m' @paddingSize='m'>
  {{this.sizeCode}}
</EuiCodeBlock>
<EuiSpacer />
<EuiFlexGrid @columns={{3}}>
  {{#each this.iconSizes as |size index|}}
    <EuiFlexItem>
      <EuiCopy
        @textToCopy={{size}}
        @beforeMessage='Click to Copy'
        @afterMessage='Copied'
        as |copy|
      >
        <EuiPanel
          @paddingSize='s'
          @hasShadow={{false}}
          @onClick={{copy}}
        >
          <EuiIcon @type='logoElasticStack' @size={{size}} />
          <small>
            {{get this.iconSizesText index}}
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
  @tracked sizeCode = `
 <EuiIcon type="logoElasticsearch" size="xl" />
`;

  @tracked iconSizes = ['s', 'm', 'l', 'xl', 'xxl', 'original'];
  @tracked iconSizesText = [
    'small',
    'medium',
    'large',
    'x-large',
    'xx-large',
    'original'
  ];
}
```
