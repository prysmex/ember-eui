---
order: 2
---

# Simple item reorder

<EuiText>
  <p>
    The simplest case, demonstrating a single <strong>EuiDroppable</strong> with <EuiCode>euiDragDropReorder</EuiCode> behavior.
  </p>
  <p>
    Notice the ability to change rendered content based on dragging state. The <strong>Draggable</strong> block yields an object whose <EuiCode>isDragging</EuiCode> property has state data that can be used to alter appearance or behavior.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiDragDropContext, EuiPanel } from '@ember-eui/core/components';
import { euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class ReorderDemo extends Component {
  @tracked list = makeList(3);

  @action
  onDragEnd({ source, destination }) {
    if (source && destination) {
      this.list = euiDragDropReorder(this.list, source.index, destination.index);
    }
  }

  <template>
    <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
      <dnd.Droppable @droppableId='DROPPABLE_AREA' @spacing='m' @withPanel={{true}} as |list|>
        {{#each this.list key='id' as |item index|}}
          <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
            <EuiPanel @hasShadow={{state.isDragging}}>
              {{item.content}}
              {{#if state.isDragging}} ✨{{/if}}
            </EuiPanel>
          </list.Draggable>
        {{/each}}
      </dnd.Droppable>
    </EuiDragDropContext>
  </template>
}
```
