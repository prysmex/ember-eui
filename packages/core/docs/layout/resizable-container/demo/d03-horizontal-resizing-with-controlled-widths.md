---
order: 3
---

# Horizontal resizing with controlled widths

<EuiText>
  <p>
    Sometimes it's necessary to control panel sizes from the outside. For example to store sizes in <EuiCode>localStorage</EuiCode> or change the layout with predefined sizes. Here is the <EuiCode>@onPanelWidthChange</EuiCode> and <EuiCode>@size</EuiCode> args for help. If you use such an approach, you have to specify an <EuiCode>@id</EuiCode> for each panel to track their sizes.
  </p>
  <p>
    <strong>Required arguments:</strong> either <EuiCode>@initialSize</EuiCode> or <EuiCode>@size</EuiCode> must be specified. The <EuiCode>@size</EuiCode> arg is for cases where a parent component will control sizing updates.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiFlexGroup, EuiFlexItem, EuiResizableContainer, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

const STORAGE_KEY = 'resizableContainer';

function readStoredSizes() {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : null;
  } catch (e) {
    return null;
  }
}

export default class ControlledWidthsDemo extends Component {
  paragraphs = [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
      'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
      'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.'
  ];

  defaultSizes = { firstPanel: 50, secondPanel: 50 };

  @tracked sizes;
  @tracked savedSizes = readStoredSizes();

  constructor() {
    super(...arguments);
    this.sizes = this.savedSizes ?? this.defaultSizes;
  }

  get isSaved() {
    return this.savedSizes === this.sizes;
  }

  @action
  onPanelWidthChange(newSizes) {
    this.sizes = { ...this.sizes, ...newSizes };
  }

  @action
  setSizes(firstPanel, secondPanel) {
    this.sizes = { firstPanel, secondPanel };
  }

  @action
  reset() {
    this.sizes = this.defaultSizes;
  }

  @action
  saveToLocalStorage() {
    this.savedSizes = this.sizes;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.sizes));
    } catch (e) {
      // storage is not available
    }
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem>
        <EuiButton {{on 'click' this.reset}}>Reset to defaults</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiButton {{on 'click' (fn this.setSizes 30 70)}}>30x70</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiButton {{on 'click' (fn this.setSizes 80 20)}}>80x20</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiButton
          @fill={{this.isSaved}}
          @iconType={{if this.isSaved 'check'}}
          {{on 'click' this.saveToLocalStorage}}
        >
          Store in localStorage
        </EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>

    <EuiSpacer />

    <EuiResizableContainer
      style='height: 200px;'
      @onPanelWidthChange={{this.onPanelWidthChange}}
      as |c|
    >
      <c.Panel @id='firstPanel' @size={{this.sizes.firstPanel}} @minSize='30%' tabindex='0'>
        <EuiText>
          <div>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</div>
        </EuiText>
      </c.Panel>
      <c.Button @accountForScrollbars='before' />
      <c.Panel @id='secondPanel' @size={{this.sizes.secondPanel}} @minSize='200px' tabindex='0'>
        <EuiText>
          <div>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</div>
        </EuiText>
      </c.Panel>
    </EuiResizableContainer>
  </template>
}
```
