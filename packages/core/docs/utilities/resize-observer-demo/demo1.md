# Demo

```hbs template
<div>
  <EuiText>
    <p>
      EuiResizeObserver is a wrapper around the Resizer Observer API which allows watching for changes to the content rectangle of DOM elements. Unlike EuiMutationObserver, EuiResizeObserver does not take parameters, but it does fire a more efficient and informative callback when resize events occur.
    </p>
    <p>
      Due to limited browser support (currently not in Safari and IE11), will fallback to using the MutationObserver API with a default set of parameters that approximate the results of EuiMutationObserver.
    </p>
  </EuiText>
  <EuiSpacer />
  <div>
    <EuiTitle>
      width:
      {{this.dimensions.width}}
      height:
      {{this.dimensions.height}}
    </EuiTitle>
    <EuiButton {{on "click" this.addItem}}>
      add item
    </EuiButton>
    <EuiSpacer />
    <EuiFlexGroup>
      <EuiFlexItem @grow={{false}}>
        <EuiPanel @grow={{false}} {{resize-observer onResize=(set this "dimensions")}}>
          <ul>
            {{#each this.items as |item|}}
              <li>
                {{item}}
              </li>
            {{/each}}
          </ul>
          <EuiSpacer size="s" />
        </EuiPanel>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="l" />
    <EuiText>
      You can also indicate to only care about width or height, for example the next panel only observers for height changes
    </EuiText>
    <EuiSpacer />
    <EuiButton {{on "click" this.increaseItemsWidth}}>
      increaseWidth
    </EuiButton>
    <EuiButton {{on "click" this.addItem}}>
      add item
    </EuiButton>
    <EuiTitle>
      width:
      {{this.dimensions2.width}}
      height:
      {{this.dimensions2.height}}
    </EuiTitle>
    <EuiSpacer />
    <EuiFlexGroup>
      <EuiFlexItem @grow={{false}}>
        <EuiPanel @grow={{false}} {{resize-observer "height" onResize=(set this "dimensions2")}}>
          <ul>
            {{#each this.items as |item|}}
              <li>
                {{item}}
              </li>
            {{/each}}
          </ul>
          <EuiSpacer size="s" />
        </EuiPanel>
      </EuiFlexItem>
    </EuiFlexGroup>
  </div>
</div>
```

```javascript component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked disabled = false;
  @tracked dimensions = {
    width: 0,
    height: 0,
  };
  @tracked dimensions2 = {
    width: 0,
    height: 0,
  };
  @tracked items = ['item 1', 'item 2', 'item 3'];
  @tracked items2 = ['item 1', 'item 2', 'item 3'];

  @action
  increaseItemsWidth() {
    this.items = this.items.map((i, ix) => `${i}${ix}`);
  }

  @action
  addItem() {
    this.items = [...this.items, `Item ${this.items.length + 1}`];
  }
}
```
