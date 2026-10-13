---
order: 2
---

# Observing only one dimension (Ember EUI extra)

<EuiText>

The modifier's first positional argument limits what it observes: <EuiCode>'height'</EuiCode> or <EuiCode>'width'</EuiCode>. The panel below only reports height changes, so lengthening an item does not fire <EuiCode>onResize</EuiCode>.

</EuiText>

```hbs template
<div>
  <EuiButton {{on 'click' this.increaseItemsWidth}}>increase width</EuiButton>
  <EuiButton {{on 'click' this.addItem}}>add item</EuiButton>
  <EuiSpacer />
  <EuiText>
    <p><EuiCode>height: {{this.dimensions.height}}; width: {{this.dimensions.width}}</EuiCode></p>
  </EuiText>
  <EuiSpacer />
  <EuiFlexGroup>
    <EuiFlexItem @grow={{false}}>
      <EuiPanel @grow={{false}} {{resize-observer 'height' onResize=this.onResize}}>
        <ul>
          {{#each this.items as |item|}}
            <li>{{item}}</li>
          {{/each}}
        </ul>
      </EuiPanel>
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ResizeObserverHeight extends Component {
  @tracked dimensions = { width: 0, height: 0 };
  @tracked items = ['Item 1', 'Item 2', 'Item 3'];

  @action
  increaseItemsWidth() {
    this.items = this.items.map((item) => `${item} and more text`);
  }

  @action
  addItem() {
    this.items = [...this.items, `Item ${this.items.length + 1}`];
  }

  @action
  onResize(dimensions) {
    this.dimensions = dimensions;
  }
}
```
