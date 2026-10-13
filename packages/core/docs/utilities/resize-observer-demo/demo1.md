---
order: 1
---

# Resize observer

<EuiText>

<strong>EuiResizeObserver</strong> is a wrapper around the <a href="https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver" target="_blank" rel="noopener noreferrer"><strong>Resizer Observer API</strong></a> which allows watching for changes to the content rectangle of DOM elements. Unlike the mutation observer, it does not take parameters, but it does fire a more efficient and informative callback when resize events occur.

In Ember EUI it is the <EuiCode>resize-observer</EuiCode> modifier: put it on the element you wish to observe. It also serves as the equivalent of upstream's <EuiCode>useResizeObserver</EuiCode> hook.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiButtonEmpty, EuiCode, EuiPanel, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { resizeObserver } from '@ember-eui/core/modifiers';
import { on } from '@ember/modifier';

export default class ResizeObserverDemo extends Component {
  @tracked paddingSize = 's';
  @tracked items = ['Item 1', 'Item 2', 'Item 3'];
  @tracked height = 0;
  @tracked width = 0;

  @action
  togglePaddingSize() {
    this.paddingSize = this.paddingSize === 's' ? 'l' : 's';
  }

  @action
  addItem() {
    this.items = [...this.items, `Item ${this.items.length + 1}`];
  }

  @action
  onResize({ height, width }) {
    this.height = height;
    this.width = width;
  }

  <template>
    <div>
      <EuiText>
        <p>
          <EuiCode>
            height:
            {{this.height}}; width:
            {{this.width}}
          </EuiCode>
        </p>
      </EuiText>
      <EuiSpacer />
      <EuiButton @fill={{true}} {{on 'click' this.togglePaddingSize}}>
        Toggle container padding
      </EuiButton>
      <EuiSpacer />
      <div class='eui-displayInlineBlock' {{resizeObserver onResize=this.onResize}}>
        <EuiPanel class='eui-displayInlineBlock' @paddingSize={{this.paddingSize}}>
          <ul>
            {{#each this.items as |item|}}
              <li>{{item}}</li>
            {{/each}}
          </ul>
          <EuiSpacer @size='s' />
          <EuiButtonEmpty {{on 'click' this.addItem}}>add item</EuiButtonEmpty>
        </EuiPanel>
      </div>
    </div>
  </template>
}
```

