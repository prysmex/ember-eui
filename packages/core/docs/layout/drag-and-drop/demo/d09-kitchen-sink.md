---
order: 9
---

# Kitchen sink

<EuiText>
  <p>
    <strong>EuiDraggables</strong> in <strong>EuiDroppables</strong>, <strong>EuiDroppables</strong> in <strong>EuiDraggables</strong>, custom drag handles, horizontal movement, vertical movement, flexbox, panel inception, you name it. The button that drags a column uses <EuiCode>@customDragHandle="custom"</EuiCode> (upstream's <EuiCode>disableInteractiveElementBlocking</EuiCode>), so the button itself is the focusable handle.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButtonIcon, EuiDragDropContext, EuiPanel, EuiToolTip } from '@ember-eui/core/components';
import { euiDragDropMove, euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';
import { concat, get } from '@ember/helper';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class KitchenSinkDemo extends Component {
  // the parent list holds the ids of the two columns
  @tracked parent = [{ did: 1 }, { did: 2 }];
  @tracked area1 = makeList(3);
  @tracked area2 = makeList(3, 4);

  get lists() {
    return {
      COMPLEX_DROPPABLE_PARENT: this.parent,
      COMPLEX_DROPPABLE_AREA_1: this.area1,
      COMPLEX_DROPPABLE_AREA_2: this.area2
    };
  }

  setList(droppableId, items) {
    if (droppableId === 'COMPLEX_DROPPABLE_PARENT') {
      this.parent = items;
    } else if (droppableId === 'COMPLEX_DROPPABLE_AREA_1') {
      this.area1 = items;
    } else {
      this.area2 = items;
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
      <dnd.Droppable
        @droppableId='COMPLEX_DROPPABLE_PARENT'
        @type='MACRO'
        @direction='horizontal'
        @withPanel={{true}}
        @spacing='l'
        style='display: flex;'
        as |parentList|
      >
        {{#each this.parent key='did' as |column index|}}
          <parentList.Draggable
            @index={{index}}
            @draggableId={{concat 'COMPLEX_DRAGGABLE_' column.did}}
            @spacing='l'
            @customDragHandle='custom'
            @hasInteractiveChildren={{true}}
            style='flex: 1 0 50%;'
            as |parentItem|
          >
            <EuiPanel @color='subdued' @paddingSize='s'>
              <EuiToolTip @content='Drag Handle' @disableScreenReaderOutput={{true}}>
                <EuiButtonIcon
                  @iconType='dragVertical'
                  aria-label='Drag Handle'
                  {{parentItem.dragHandle}}
                />
              </EuiToolTip>
              <dnd.Droppable
                @droppableId={{concat 'COMPLEX_DROPPABLE_AREA_' column.did}}
                @type='MICRO'
                @spacing='m'
                style='flex: 1 0 50%;'
                as |childList|
              >
                {{#each (get this.lists (concat 'COMPLEX_DROPPABLE_AREA_' column.did)) key='id' as |item idx|}}
                  <childList.Draggable @index={{idx}} @draggableId={{item.id}} @spacing='m'>
                    <EuiPanel>{{item.content}}</EuiPanel>
                  </childList.Draggable>
                {{/each}}
              </dnd.Droppable>
            </EuiPanel>
          </parentList.Draggable>
        {{/each}}
      </dnd.Droppable>
    </EuiDragDropContext>
  </template>
}
```
