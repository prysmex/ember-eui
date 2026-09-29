---
order: 2
---

# Move between lists

<EuiText>

Two lists of the same type: items move between them with
`euiDragDropMove`. "Done" is locked while the switch is on.

</EuiText>

```hbs template
<EuiSwitch @label="Lock the Done list" @checked={{this.locked}} {{on "change" this.toggleLock}} />
<EuiSpacer />
<EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiTitle @size="xxs"><h3>To do</h3></EuiTitle>
      <EuiSpacer @size="s" />
      <dnd.Droppable @droppableId="todo" @spacing="m" @withPanel={{true}} @grow={{true}} as |list|>
        {{#each this.lists.todo key="id" as |item index|}}
          <list.Draggable @draggableId={{item.id}} @index={{index}} @spacing="m">
            <EuiPanel @paddingSize="s">{{item.label}}</EuiPanel>
          </list.Draggable>
        {{/each}}
      </dnd.Droppable>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiTitle @size="xxs"><h3>Done</h3></EuiTitle>
      <EuiSpacer @size="s" />
      <dnd.Droppable
        @droppableId="done"
        @spacing="m"
        @withPanel={{true}}
        @grow={{true}}
        @isDropDisabled={{this.locked}}
        as |list|
      >
        {{#each this.lists.done key="id" as |item index|}}
          <list.Draggable @draggableId={{item.id}} @index={{index}} @spacing="m">
            <EuiPanel @paddingSize="s" @color="success">{{item.label}}</EuiPanel>
          </list.Draggable>
        {{/each}}
      </dnd.Droppable>
    </EuiFlexItem>
  </EuiFlexGroup>
</EuiDragDropContext>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { euiDragDropMove, euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';

export default class MoveBetweenLists extends Component {
  @tracked locked = false;
  @tracked lists = {
    todo: [
      { id: 'milk', label: 'Buy milk' },
      { id: 'mail', label: 'Answer the mail' },
      { id: 'plants', label: 'Water the plants' },
    ],
    done: [{ id: 'bike', label: 'Fix the bike' }],
  };

  @action
  toggleLock(event) {
    this.locked = event.target.checked;
  }

  @action
  onDragEnd({ source, destination }) {
    if (!destination) return;

    if (source.droppableId === destination.droppableId) {
      this.lists = {
        ...this.lists,
        [source.droppableId]: euiDragDropReorder(
          this.lists[source.droppableId],
          source.index,
          destination.index,
        ),
      };
    } else {
      this.lists = {
        ...this.lists,
        ...euiDragDropMove(
          this.lists[source.droppableId],
          this.lists[destination.droppableId],
          source,
          destination,
        ),
      };
    }
  }
}
```
