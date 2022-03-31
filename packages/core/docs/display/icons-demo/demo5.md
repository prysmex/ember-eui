---
order: 5
---

# Machine learning icons

<EuiText>
  <p>Machine learning has some specific icons for job creation. Again, these are made for <EuiCode @language="text">32x32</EuiCode>.</p>
</EuiText>

```hbs template
<EuiCodeBlock @language='html' @fontSize='m' @paddingSize='m'>
  {{this.mlCode}}
</EuiCodeBlock>
<EuiSpacer />
<EuiFlexGrid @columns={{3}}>
  {{#each this.ml as |icon|}}
    <EuiFlexItem>
      <EuiCopy
        @textToCopy={{icon}}
        @beforeMessage='Click to Copy'
        @afterMessage='Copied'
        as |copy|
      >
        <EuiPanel
          @paddingSize='s'
          @hasShadow={{false}}
          @onClick={{copy}}
        >
          <EuiIcon @type='{{icon}}' @size='xl' />
          <small>
            {{icon}}
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
  @tracked mlCode = `
<EuiIcon type="dataVisualizer" size="xl" />
`;

  @tracked ml = [
    'dataVisualizer',
    'createAdvancedJob',
    'classificationJob',
    'createMultiMetricJob',
    'outlierDetectionJob',
    'createPopulationJob',
    'regressionJob',
    'createSingleMetricJob'
  ];
}
```
