---
order: 2
---

# Scroll anchoring

<EuiText>

Scroll down a bit, then grow the first twenty rows. With the anchor on,
the rows you were looking at stay in place; turn it off and they jump
down.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="m" @alignItems="center" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch
      @label="Anchor the first visible row"
      @checked={{this.anchored}}
      @onChange={{this.toggleAnchor}}
    />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.toggleGrown}}>
      {{if this.grown "Shrink" "Grow"}} the first 20 rows
    </EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="m" />
<EuiDataGrid
  aria-label="Scroll anchor demo"
  @columns={{this.columns}}
  @rowCount={{500}}
  @height={{320}}
  @toolbarVisibility={{false}}
  @rowHeightsOptions={{this.rowHeightsOptions}}
>
  <:cell as |cell|>{{cell.columnId}} {{cell.rowIndex}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ScrollAnchorDemo extends Component {
  @tracked anchored = true;
  @tracked grown = false;

  columns = [
    { id: 'row', displayAsText: 'Row' },
    { id: 'value', displayAsText: 'Value' }
  ];

  get rowHeightsOptions() {
    const rowHeights = {};
    if (this.grown) {
      for (let i = 0; i < 20; i++) rowHeights[i] = { height: 80 };
    }
    return {
      rowHeights,
      ...(this.anchored ? { scrollAnchorRow: 'start' } : {})
    };
  }

  @action toggleAnchor() {
    this.anchored = !this.anchored;
  }

  @action toggleGrown() {
    this.grown = !this.grown;
  }
}
```
