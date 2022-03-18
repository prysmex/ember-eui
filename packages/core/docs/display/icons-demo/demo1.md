```hbs template
<EuiTitle @size='m'>
  Glyphs
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Glyphs are small, monochromatic icons that typically should always use the
    default size of size="m".
  </p>
</EuiText>
<EuiSpacer />
<EuiCodeBlock @language='html' @fontSize='m' @paddingSize='m'>
  {{this.javascriptCode}}
</EuiCodeBlock>
<EuiSpacer />
<EuiFlexGrid @columns={{3}}>
  {{#each this.glyphs as |icon|}}
    <EuiFlexItem>
      <EuiCopy
        @textToCopy={{icon}}
        @beforeMessage='Click to Copy'
        @afterMessage='Copied'
        as |copy|
      >
        <EuiPanel @paddingSize='s' {{on 'click' copy}} @color='subdued'>
          <EuiIcon @type='{{icon}}' />
          <small>
            {{icon}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
<EuiSpacer />
<EuiSpacer />
<EuiTitle @size='m'>
  Editor controls
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Editor icons relate to the visual styling of elements and are commonly used
    within EuiButtonGroup components.
  </p>
</EuiText>
<EuiSpacer />
<EuiFlexGrid @columns={{3}}>
  {{#each this.editor as |icon|}}
    <EuiFlexItem>
      <EuiCopy
        @textToCopy={{icon}}
        @beforeMessage='Click to Copy'
        @afterMessage='Copied'
        as |copy|
      >
        <EuiPanel @paddingSize='s' {{on 'click' copy}} @color='subdued'>
          <EuiIcon @type='{{icon}}' />
          <small>
            {{icon}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
<EuiSpacer />
<EuiSpacer />
<EuiTitle @size='m'>
  Elastic logos
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    These logos are restricted in use to Elastic products or when referencing
    Elastic products. They are multi-color with some internal paths having a
    class of .euiIcon__fillNegative to handle flipping colors for dark mode. The
    only other colors most of them support are ghost and text which turn them
    into a solid shape.
  </p>
</EuiText>
<EuiSpacer />
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
        <EuiPanel @paddingSize='s' {{on 'click' copy}} @color='subdued'>
          <EuiIcon @type='{{icon}}' @size='xl' />
          <small>
            {{icon}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>

<EuiSpacer />
<EuiSpacer />
<EuiTitle @size='m'>
  Apps
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    App logos are usually displayed at 32x32 or above and can contain multiple
    colors.
  </p>
</EuiText>
<EuiSpacer />
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
        <EuiPanel @paddingSize='s' {{on 'click' copy}} @color='subdued'>
          <EuiIcon @type='{{icon}}' @size='xl' />
          <small>
            {{icon}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
<EuiSpacer />
<EuiSpacer />
<EuiTitle @size='m'>
  Machine learning icons
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Machine learning has some specific icons for job creation. Again, these are
    made for 32x32.
  </p>
</EuiText>
<EuiSpacer />
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
        <EuiPanel @paddingSize='s' {{on 'click' copy}} @color='subdued'>
          <EuiIcon @type='{{icon}}' @size='xl' />
          <small>
            {{icon}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
<EuiSpacer />
<EuiSpacer />
<EuiTitle @size='m'>
  Sizes
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Use the size prop to automatically size your icons. Medium is the default,
    and will output a 16x16 icon.
  </p>
</EuiText>
<EuiSpacer />
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
        <EuiPanel @paddingSize='s' {{on 'click' copy}} @color='subdued'>
          <EuiIcon @type='logoElasticStack' @size={{size}} />
          <small>
            {{get this.iconSizesText index}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
<EuiSpacer />
<EuiSpacer />
<EuiTitle @size='m'>
  Colors
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    The default behavior of icons is to inherit from the text color. You can use
    the color prop to assign a custom color which accepts a named color from our
    palette or a valid CSS color data type(opens in a new tab or window) which
    will be passed down through the inline-style fill property. We recommend
    relying on the EUI named color palette unless the custom color is initiated
    by the user (like as a graph color).
  </p>
</EuiText>

<EuiSpacer />
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
        <EuiPanel @paddingSize='s' {{on 'click' copy}} @color='subdued'>
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
<p>
  Two-tone icons, like our app style icons, will behave similarly to normal
  glyphs when provided a specific color by applying the color to all the shapes
  within. You can force the icon to match the parent's text color by passing
  color="inherit" to the icon.
</p>
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
        <EuiPanel @paddingSize='s' {{on 'click' copy}} @color='subdued'>
          <EuiIcon @type='gisApp' @color={{color}} />
          <small>
            {{color}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
<EuiSpacer />
<EuiSpacer />
<EuiTitle @size='m'>
  Custom SVGs
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    The type prop can accept a valid enum, string or React SVG Element. When
    using a custom SVG, please make sure it sits on a square canvas and
    preferably utilizes one of EUI's sizes (16x16 or 32x32). When using custom
    SVGs for simple glyphs, remove all fill attributes on the SVG and utilize
    the CSS helpers if you have complex logos that need to work with theming.
  </p>
</EuiText>
<EuiSpacer />
<EuiFlexGrid @columns={{2}}>
  <EuiPanel @paddingSize='s' @color='subdued'>
    <EuiFlexItem>
      <EuiIcon
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
  @tracked icon = 'tokenNumber';
  icons = iconKeys;

  @action
  update() {
    this.icon = this.icons[Math.floor(Math.random() * this.icons.length)];
  }

  @tracked javascriptCode = `
 <EuiIcon @type='accessibility' />
`;

  @tracked elasticCode = `
<EuiIcon type="logoElasticsearch" size="xl" />
`;

  @tracked appsCode = `
<EuiIcon type="addDataApp" size="xl" />
`;

  @tracked mlCode = `
<EuiIcon type="dataVisualizer" size="xl" />
`;

  @tracked sizeCode = `
 <EuiIcon type="logoElasticsearch" size="xl" />
`;

  @tracked colorCode = `
 <EuiIcon type="brush" color="primary" />
`;

  @tracked colorinherit = `
 <EuiIcon type="gisApp" color="primary" />
`;

  @tracked customsvg = `
 <EuiIcon type="https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg" size="xl" title="My SVG logo" />
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

  @tracked glyphs = [
    'accessibility',
    'aggregate',
    'alert',
    'analyzeEvent',
    'annotation',
    'apmTrace',
    'apps',
    'arrowDown',
    'arrowLeft',
    'arrowRight',
    'arrowUp',
    'asterisk',
    'beaker',
    'bell',
    'bellSlash',
    'bolt',
    'boxesHorizontal',
    'boxesVertical',
    'branch',
    'broom',
    'brush',
    'bug',
    'bullseye',
    'calendar',
    'check',
    'checkInCircleFilled',
    'cheer',
    'clock',
    'cloudDrizzle',
    'cloudStormy',
    'cloudSunny',
    'color',
    'compute',
    'console',
    'continuityAbove',
    'continuityAboveBelow',
    'continuityBelow',
    'continuityWithin',
    'controlsHorizontal',
    'controlsVertical',
    'copy',
    'copyClipboard',
    'cross',
    'crosshairs',
    'crossInACircleFilled',
    'currency',
    'cut',
    'database',
    'document',
    'documentation',
    'documentEdit',
    'documents',
    'dot',
    'download',
    'email',
    'empty',
    'eql',
    'eraser',
    'exit',
    'expand',
    'expandMini',
    'exportAction',
    'eye',
    'eyeClosed',
    'faceHappy',
    'faceNeutral',
    'faceSad',
    'filter',
    'flag',
    'fold',
    'folderCheck',
    'folderClosed',
    'folderExclamation',
    'folderOpen',
    'frameNext',
    'framePrevious',
    'fullScreen',
    'fullScreenExit',
    'function',
    'gear',
    'glasses',
    'globe',
    'grab',
    'grabHorizontal',
    'grid',
    'heart',
    'heatmap',
    'help',
    'home',
    'iInCircle',
    'image',
    'importAction',
    'indexClose',
    'indexEdit',
    'indexFlush',
    'indexMapping',
    'indexOpen',
    'indexRuntime',
    'indexSettings',
    'inputOutput',
    'inspect',
    'invert',
    'ip',
    'keyboardShortcut',
    'kqlField',
    'kqlFunction',
    'kqlOperand',
    'kqlSelector',
    'kqlValue',
    'layers',
    'link',
    'list',
    'listAdd',
    'lock',
    'lockOpen',
    'logstashFilter',
    'logstashIf',
    'logstashInput',
    'logstashOutput',
    'logstashQueue',
    'magnifyWithMinus',
    'magnifyWithPlus',
    'magnet',
    'mapMarker',
    'memory',
    'merge',
    'menu',
    'menuDown',
    'menuLeft',
    'menuRight',
    'menuUp',
    'minimize',
    'minus',
    'minusInCircle',
    'minusInCircleFilled',
    'mobile',
    'moon',
    'nested',
    'node',
    'number',
    'offline',
    'online',
    'package',
    'pageSelect',
    'pagesSelect',
    'paperClip',
    'partial',
    'pause',
    'payment',
    'pencil',
    'percent',
    'pin',
    'pinFilled',
    'play',
    'playFilled',
    'plus',
    'plusInCircle',
    'plusInCircleFilled',
    'popout',
    'push',
    'questionInCircle',
    'quote',
    'refresh',
    'reporter',
    'returnKey',
    'save',
    'scale',
    'search',
    'securitySignal',
    'securitySignalDetected',
    'securitySignalResolved',
    'shard',
    'share',
    'snowflake',
    'sortable',
    'sortDown',
    'sortLeft',
    'sortRight',
    'sortUp',
    'starEmpty',
    'starEmptySpace',
    'starFilled',
    'starFilledSpace',
    'starMinusEmpty',
    'starMinusFilled',
    'starPlusEmpty',
    'starPlusFilled',
    'stats',
    'stop',
    'stopFilled',
    'stopSlash',
    'storage',
    'string',
    'submodule',
    'symlink',
    'tableOfContents',
    'tableDensityExpanded',
    'tableDensityCompact',
    'tableDensityNormal',
    'tag',
    'tear',
    'temperature',
    'timeline',
    'timeslider',
    'training',
    'trash',
    'unfold',
    'unlink',
    'user',
    'users',
    'vector',
    'videoPlayer',
    'visArea',
    'visAreaStacked',
    'visBarHorizontal',
    'visBarHorizontalStacked',
    'visBarVertical',
    'visBarVerticalStacked',
    'visGauge',
    'visGoal',
    'visLine',
    'visMapCoordinate',
    'visMapRegion',
    'visMetric',
    'visPie',
    'visTable',
    'visTagCloud',
    'visText',
    'visTimelion',
    'visVega',
    'visVisualBuilder',
    'wordWrap',
    'wordWrapDisabled',
    'wrench'
  ];

  @tracked editor = [
    'editorAlignCenter',
    'editorAlignLeft',
    'editorAlignRight',
    'editorBold',
    'editorCodeBlock',
    'editorComment',
    'editorDistributeHorizontal',
    'editorDistributeVertical',
    'editorHeading',
    'editorItalic',
    'editorItemAlignBottom',
    'editorItemAlignCenter',
    'editorItemAlignLeft',
    'editorItemAlignMiddle',
    'editorItemAlignRight',
    'editorItemAlignTop',
    'editorLink',
    'editorOrderedList',
    'editorPositionBottomLeft',
    'editorPositionBottomRight',
    'editorPositionTopLeft',
    'editorPositionTopRight',
    'editorRedo',
    'editorStrike',
    'editorTable',
    'editorUnderline',
    'editorUndo',
    'editorUnorderedList'
  ];

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

  @tracked tokens = [
    'tokenString',
    'tokenNumber',
    'tokenBoolean',
    'tokenDate',
    'tokenGeo',
    'tokenIP',
    'tokenShape',
    'tokenNested',
    'tokenAlias',
    'tokenRange',
    'tokenAnnotation',
    'tokenArray',
    'tokenClass',
    'tokenConstant',
    'tokenElement',
    'tokenEnum',
    'tokenEnumMember',
    'tokenEvent',
    'tokenException',
    'tokenField',
    'tokenFunction',
    'tokenInterface',
    'tokenKey',
    'tokenMethod',
    'tokenModule',
    'tokenNamespace',
    'tokenNull',
    'tokenObject',
    'tokenOperator',
    'tokenPackage',
    'tokenParameter',
    'tokenProperty',
    'tokenStruct',
    'tokenVariable',
    'tokenFile',
    'tokenSymbol',
    'tokenRepo',
    'tokenBinary',
    'tokenJoin',
    'tokenPercolator',
    'tokenFlattened',
    'tokenRankFeature',
    'tokenRankFeatures',
    'tokenKeyword',
    'tokenTag',
    'tokenCompletionSuggester',
    'tokenDenseVector',
    'tokenText',
    'tokenTokenCount',
    'tokenSearchType',
    'tokenHistogram'
  ];
}
```
