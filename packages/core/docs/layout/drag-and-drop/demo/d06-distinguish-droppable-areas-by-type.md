---
order: 6
---

# Distinguish droppable areas by type

<EuiText>
  <p>
    Setting the <EuiCode>@type</EuiCode> arg on an <strong>EuiDroppable</strong> element will ensure that it will only accept <strong>EuiDraggable</strong> elements from the same type of <strong>EuiDroppable</strong>.
  </p>
  <p>
    Notice that the enabled, compatible <strong>EuiDroppable</strong> elements have a visual change that indicates they can accept the actively moving/focused <strong>EuiDraggable</strong> element.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiDragDropContext, EuiFlexGroup, EuiFlexItem, EuiPanel } from '@ember-eui/core/components';
import { euiDragDropMove, euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class TypeDemo extends Component {
  @tracked list1 = makeList(3);
  @tracked list2 = makeList(3, 4);
  @tracked list3 = makeList(3, 7);

  get lists() {
    return {
      DROPPABLE_AREA_TYPE_1: this.list1,
      DROPPABLE_AREA_TYPE_2: this.list2,
      DROPPABLE_AREA_TYPE_3: this.list3
    };
  }

  setList(droppableId, items) {
    if (droppableId === 'DROPPABLE_AREA_TYPE_1') {
      this.list1 = items;
    } else if (droppableId === 'DROPPABLE_AREA_TYPE_2') {
      this.list2 = items;
    } else {
      this.list3 = items;
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
              <dnd.Droppable
                @droppableId='DROPPABLE_AREA_TYPE_1'
                @type='TYPE_ONE'
                @spacing='m'
                @withPanel={{true}}
                @grow={{false}}
                as |list|
              >
                {{#each this.list1 key='id' as |item index|}}
                <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
                  <EuiPanel @hasShadow={{state.isDragging}}>
                    {{item.content}}
                    {{#if state.isDragging}} ✨{{/if}}
                  </EuiPanel>
                </list.Draggable>
                {{/each}}
              </dnd.Droppable>
            </EuiFlexItem>
            <EuiFlexItem>
              <dnd.Droppable
                @droppableId='DROPPABLE_AREA_TYPE_2'
                @type='TYPE_ONE'
                @spacing='m'
                @withPanel={{true}}
                @grow={{false}}
                as |list|
              >
                {{#each this.list2 key='id' as |item index|}}
                <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
                  <EuiPanel @hasShadow={{state.isDragging}}>
                    {{item.content}}
                    {{#if state.isDragging}} ✨{{/if}}
                  </EuiPanel>
                </list.Draggable>
                {{/each}}
              </dnd.Droppable>
            </EuiFlexItem>
            <EuiFlexItem>
              <dnd.Droppable
                @droppableId='DROPPABLE_AREA_TYPE_3'
                @type='TYPE_TWO'
                @spacing='m'
                @withPanel={{true}}
                @grow={{true}}
                as |list|
              >
                {{#each this.list3 key='id' as |item index|}}
                <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
                  <EuiPanel @hasShadow={{state.isDragging}}>
                    {{item.content}}
                    {{#if state.isDragging}} ✨{{/if}}
                  </EuiPanel>
                </list.Draggable>
                {{/each}}
              </dnd.Droppable>
            </EuiFlexItem>
      </EuiFlexGroup>
    </EuiDragDropContext>
  </template>
}
```
