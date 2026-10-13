---
order: 5
---

# Move between lists

<EuiText>
  <p>
    By default, all <strong>EuiDroppable</strong> elements are of the same type and will accept <strong>EuiDraggable</strong> elements from others in the same <strong>EuiDragDropContext</strong>.
  </p>
  <p>
    The EUI <EuiCode>euiDragDropMove</EuiCode> method is demonstrated in this example.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiDragDropContext, EuiFlexGroup, EuiFlexItem, EuiIcon, EuiPanel } from '@ember-eui/core/components';
import { euiDragDropMove, euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class MoveDemo extends Component {
  @tracked list1 = makeList(3);
  @tracked list2 = makeList(3, 4);

  get lists() {
    return {
      DROPPABLE_AREA_1: this.list1,
      DROPPABLE_AREA_2: this.list2
    };
  }

  setList(droppableId, items) {
    if (droppableId === 'DROPPABLE_AREA_1') {
      this.list1 = items;
    } else {
      this.list2 = items;
    }
  }

  @action
  onDragEnd({ source, destination }) {
    if (source && destination) {
      const lists = this.lists;
      if (source.droppableId === destination.droppableId) {
        const items = euiDragDropReorder(
          lists[destination.droppableId],
          source.index,
          destination.index
        );
        this.setList(destination.droppableId, items);
      } else {
        const sourceId = source.droppableId;
        const destinationId = destination.droppableId;
        const result = euiDragDropMove(
          lists[sourceId],
          lists[destinationId],
          source,
          destination
        );
        this.setList(sourceId, result[sourceId]);
        this.setList(destinationId, result[destinationId]);
      }
    }
  }

  <template>
    <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
      <EuiFlexGroup>
            <EuiFlexItem>
              <dnd.Droppable @droppableId='DROPPABLE_AREA_1' @spacing='m' @withPanel={{true}} @grow={{false}} as |list|>
                {{#each this.list1 key='id' as |item index|}}
                <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
                  <EuiPanel @hasShadow={{state.isDragging}}>
                    {{item.content}}
                    {{#if state.isDragging}} ✨{{/if}}
                  </EuiPanel>
                </list.Draggable>
                {{else}}
                <EuiFlexGroup
                  @alignItems='center'
                  @justifyContent='spaceAround'
                  @gutterSize='none'
                  style='height: 100%;'
                >
                  <EuiFlexItem @grow={{false}}>
                    <EuiIcon @type='faceSad' />
                  </EuiFlexItem>
                </EuiFlexGroup>
                {{/each}}
              </dnd.Droppable>
            </EuiFlexItem>
            <EuiFlexItem>
              <dnd.Droppable @droppableId='DROPPABLE_AREA_2' @spacing='m' @withPanel={{true}} @grow={{false}} as |list|>
                {{#each this.list2 key='id' as |item index|}}
                <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
                  <EuiPanel @hasShadow={{state.isDragging}}>
                    {{item.content}}
                    {{#if state.isDragging}} ✨{{/if}}
                  </EuiPanel>
                </list.Draggable>
                {{else}}
                <EuiFlexGroup
                  @alignItems='center'
                  @justifyContent='spaceAround'
                  @gutterSize='none'
                  style='height: 100%;'
                >
                  <EuiFlexItem @grow={{false}}>
                    <EuiIcon @type='faceSad' />
                  </EuiFlexItem>
                </EuiFlexGroup>
                {{/each}}
              </dnd.Droppable>
            </EuiFlexItem>
      </EuiFlexGroup>
    </EuiDragDropContext>
  </template>
}
```
