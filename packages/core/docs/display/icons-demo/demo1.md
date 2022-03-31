---
order: 1
---

# Glyphs

<EuiText>
 <p>Glyphs are small, monochromatic icons that typically should always use the default size of <EuiCode @language="js">size<span class="token operator">=</span><span class="token string">"m"</span></EuiCode>.</p>
</EuiText>

```hbs template
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
        <EuiPanel
          @paddingSize='s'
          {{on 'click' copy}}
          @hasShadow={{false}}
          @isClickable={{true}}
        >
          <EuiIcon @type='{{icon}}' />
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
  @tracked javascriptCode = `
 <EuiIcon @type='accessibility' />
`;

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
}
```
