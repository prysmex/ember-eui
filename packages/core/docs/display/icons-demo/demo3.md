---
order: 3
---

# Elastic logos

<EuiText>
  <p>These logos are restricted in use to Elastic products or when referencing Elastic products. They are multi-color with some internal paths having a class of <EuiCode @language="text">.euiIcon__fillNegative</EuiCode> to handle flipping colors for dark mode. The only other colors most of them support are ghost and text which turn them into a solid shape.</p>
</EuiText>

```hbs template
<EuiCodeBlock @language='html' @fontSize='m' @paddingSize='m'>
  {{this.elasticCode}}
</EuiCodeBlock>
<EuiSpacer />

<EuiFlexGrid @columns={{3}}>
  {{#each this.logos as |icon|}}
    <EuiFlexItem>
      <EuiCopy
        @textToCopy={{icon}}
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
  @tracked elasticCode = `
<EuiIcon type="logoElasticsearch" size="xl" />
`;

  @tracked logos = [
    'logoElastic',
    'logoElasticStack',
    'logoElasticsearch',
    'logoAppSearch',
    'logoBeats',
    'logoBusinessAnalytics',
    'logoCloud',
    'logoCloudEnterprise',
    'logoEnterpriseSearch',
    'logoKibana',
    'logoLogging',
    'logoLogstash',
    'logoMaps',
    'logoMetrics',
    'logoObservability',
    'logoSecurity',
    'logoSiteSearch',
    'logoUptime',
    'logoWorkplaceSearch'
  ];
}
```
