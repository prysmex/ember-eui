---
order: 1
---

# Reorder a list

<EuiText>

Drag the items, or focus one and press Space, the arrow keys, and Space
again.

</EuiText>

```hbs template
<EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
  <dnd.Droppable @droppableId="tasks" @spacing="m" @withPanel={{true}} as |list|>
    {{#each this.items key="id" as |item index|}}
      <list.Draggable @draggableId={{item.id}} @index={{index}} @spacing="m">
        <EuiPanel @paddingSize="s">
          <EuiFlexGroup @gutterSize="s" @alignItems="center" @responsive={{false}}>
            <EuiFlexItem @grow={{false}}><EuiIcon @type="grab" /></EuiFlexItem>
            <EuiFlexItem>{{item.label}}</EuiFlexItem>
          </EuiFlexGroup>
        </EuiPanel>
      </list.Draggable>
    {{/each}}
  </dnd.Droppable>
</EuiDragDropContext>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';

export default class ReorderDemo extends Component {
  @tracked items = [
    { id: 'design', label: 'Design the page' },
    { id: 'build', label: 'Build the components' },
    { id: 'test', label: 'Write the tests' },
    { id: 'ship', label: 'Ship it' },
  ];

  @action
  onDragEnd({ source, destination }) {
    if (destination) {
      this.items = euiDragDropReorder(this.items, source.index, destination.index);
    }
  }
}
```
