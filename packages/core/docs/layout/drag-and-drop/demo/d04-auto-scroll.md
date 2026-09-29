---
order: 4
---

# Auto scroll

<EuiText>

Each list scrolls on its own and the board scrolls sideways (with the
yielded `dnd.autoScroll` modifier): drag an item near an edge and the
closest one scrolls.

</EuiText>

```hbs template
<EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
  <div style="display: flex; gap: 16px; overflow-x: auto; max-width: 520px; padding-bottom: 8px;" {{dnd.autoScroll}}>
    {{#each this.columns key="id" as |column|}}
      <div style="flex: 0 0 200px;">
        <EuiTitle @size="xxs"><h3>{{column.title}}</h3></EuiTitle>
        <EuiSpacer @size="s" />
        <dnd.Droppable
          @droppableId={{column.id}}
          @spacing="s"
          @withPanel={{true}}
          style="height: 220px; overflow-y: auto;"
          as |list|
        >
          {{#each column.items key="id" as |item index|}}
            <list.Draggable @draggableId={{item.id}} @index={{index}} @spacing="s">
              <EuiPanel @paddingSize="s">{{item.label}}</EuiPanel>
            </list.Draggable>
          {{/each}}
        </dnd.Droppable>
      </div>
    {{/each}}
  </div>
</EuiDragDropContext>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { euiDragDropMove, euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';

const column = (id, title, count) => ({
  id,
  title,
  items: Array.from({ length: count }, (_, i) => ({ id: `${id}-${i}`, label: `${title} ${i + 1}` })),
});

export default class AutoScrollDemo extends Component {
  @tracked columns = [
    column('backlog', 'Backlog', 12),
    column('doing', 'Doing', 4),
    column('review', 'Review', 6),
    column('done', 'Done', 9),
  ];

  @action
  onDragEnd({ source, destination }) {
    if (!destination) return;

    const byId = Object.fromEntries(this.columns.map((c) => [c.id, c.items]));
    const lists =
      source.droppableId === destination.droppableId
        ? { [source.droppableId]: euiDragDropReorder(byId[source.droppableId], source.index, destination.index) }
        : euiDragDropMove(byId[source.droppableId], byId[destination.droppableId], source, destination);

    this.columns = this.columns.map((c) => (lists[c.id] ? { ...c, items: lists[c.id] } : c));
  }
}
```
