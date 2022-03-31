---
order: 4
---

# Apps

<EuiText>
  <p>App logos are usually displayed at <EuiCode @language="text">32x32</EuiCode> or above and can contain multiple colors.</p>
</EuiText>

```hbs template
<EuiCodeBlock @language='html' @fontSize='m' @paddingSize='m'>
  {{this.appsCode}}
</EuiCodeBlock>
<EuiSpacer />
<EuiFlexGrid @columns={{3}}>
  {{#each this.apps as |icon|}}
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
  @tracked appsCode = `
<EuiIcon type="addDataApp" size="xl" />
`;

  @tracked apps = [
    'addDataApp',
    'advancedSettingsApp',
    'agentApp',
    'apmApp',
    'appSearchApp',
    'auditbeatApp',
    'canvasApp',
    'codeApp',
    'consoleApp',
    'crossClusterReplicationApp',
    'dashboardApp',
    'devToolsApp',
    'discoverApp',
    'emsApp',
    'filebeatApp',
    'fleetApp',
    'gisApp',
    'graphApp',
    'grokApp',
    'heartbeatApp',
    'indexManagementApp',
    'indexPatternApp',
    'indexRollupApp',
    'lensApp',
    'logsApp',
    'machineLearningApp',
    'managementApp',
    'metricbeatApp',
    'metricsApp',
    'monitoringApp',
    'notebookApp',
    'packetbeatApp',
    'pipelineApp',
    'recentlyViewedApp',
    'reportingApp',
    'savedObjectsApp',
    'searchProfilerApp',
    'securityAnalyticsApp',
    'securityApp',
    'spacesApp',
    'sqlApp',
    'timelionApp',
    'upgradeAssistantApp',
    'uptimeApp',
    'usersRolesApp',
    'visualizeApp',
    'watchesApp',
    'workplaceSearchApp'
  ];
}
```
