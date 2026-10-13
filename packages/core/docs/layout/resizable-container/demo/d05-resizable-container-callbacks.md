---
order: 5
---

# Resizable container callbacks

<EuiText>
  <p>
    <strong>EuiResizableContainer</strong> supports <EuiCode>@onResizeStart</EuiCode> and <EuiCode>@onResizeEnd</EuiCode> callback args to listen for when resizing starts and ends. The <EuiCode>@onResizeStart</EuiCode> callback is passed a <EuiCode>trigger: 'pointer' | 'key'</EuiCode> parameter to determine which user action triggered the resize.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiFlexGroup, EuiFlexItem, EuiPanel, EuiResizableContainer, EuiStat, EuiText } from '@ember-eui/core/components';
import { action } from '@ember/object';
import { not, or } from 'ember-truth-helpers';

export default class CallbacksDemo extends Component {
  paragraphs = [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
      'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
      'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.'
  ];

  @tracked resizeTrigger;
  @tracked sizes = { firstPanel: 50, secondPanel: 50 };

  get firstPanelSize() {
    return `${Math.round(this.sizes.firstPanel)}%`;
  }

  get secondPanelSize() {
    return `${Math.round(this.sizes.secondPanel)}%`;
  }

  @action
  onPanelWidthChange(newSizes) {
    this.sizes = { ...this.sizes, ...newSizes };
  }

  @action
  onResizeStart(trigger) {
    this.resizeTrigger = trigger;
  }

  @action
  onResizeEnd() {
    this.resizeTrigger = undefined;
  }

  <template>
    <EuiFlexGroup @direction='column'>
      <EuiFlexItem>
        <EuiFlexGroup>
          <EuiFlexItem>
            <EuiPanel>
              <EuiStat
                @title={{or this.resizeTrigger ''}}
                @titleSize='m'
                @description='Trigger'
                @isLoading={{not this.resizeTrigger}}
              />
            </EuiPanel>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiPanel>
              <EuiStat
                @title={{this.firstPanelSize}}
                @titleSize='m'
                @description='First panel'
                @isLoading={{not this.resizeTrigger}}
              />
            </EuiPanel>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiPanel>
              <EuiStat
                @title={{this.secondPanelSize}}
                @titleSize='m'
                @description='Second panel'
                @isLoading={{not this.resizeTrigger}}
              />
            </EuiPanel>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiResizableContainer
          style='height: 200px;'
          @onPanelWidthChange={{this.onPanelWidthChange}}
          @onResizeStart={{this.onResizeStart}}
          @onResizeEnd={{this.onResizeEnd}}
          as |c|
        >
          <c.Panel @id='firstPanel' @size={{this.sizes.firstPanel}} @minSize='30%' tabindex='0'>
            <EuiText>
              <div>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</div>
              <a href=''>Hello world</a>
            </EuiText>
          </c.Panel>
          <c.Button @accountForScrollbars='before' />
          <c.Panel @id='secondPanel' @size={{this.sizes.secondPanel}} @minSize='200px' tabindex='0'>
            <EuiText>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</EuiText>
          </c.Panel>
        </EuiResizableContainer>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
