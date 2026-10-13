---
order: 7
---

# Copyable items

<EuiText>
  <p>
    For cases where collections of <strong>EuiDraggable</strong> elements are static or can be used in multiple places set <EuiCode>@cloneDraggables=&#123;&#123;true&#125;&#125;</EuiCode> on the parent <strong>EuiDroppable</strong>. The <strong>EuiDroppable</strong> becomes disabled (does not accept new <strong>EuiDraggable</strong> elements) in this scenario to avoid mixed content intentions.
  </p>
  <p>
    The EUI <EuiCode>euiDragDropCopy</EuiCode> method is available and demonstrated in the example below. Note that the data point used as <EuiCode>@draggableId</EuiCode> in <strong>EuiDraggable</strong> must change to allow for real duplication.
  </p>
  <p>
    <EuiCode>@isRemovable</EuiCode> is used in the example for cloned items. This API is likely to change, but currently provides the visual changes with drop-to-remove interactions.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButtonIcon, EuiDragDropContext, EuiFlexGroup, EuiFlexItem, EuiIcon, EuiPanel, EuiToolTip } from '@ember-eui/core/components';
import { euiDragDropCopy, euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class CopyDemo extends Component {
  @tracked isItemRemovable = false;
  @tracked list1 = makeList(3);
  @tracked list2 = [];

  setList(droppableId, items) {
    if (droppableId === 'DROPPABLE_AREA_COPY_1') {
      this.list1 = items;
    } else {
      this.list2 = items;
    }
  }

  get lists() {
    return {
      DROPPABLE_AREA_COPY_1: this.list1,
      DROPPABLE_AREA_COPY_2: this.list2
    };
  }

  @action
  remove(droppableId, index) {
    const list = Array.from(this.lists[droppableId]);
    list.splice(index, 1);
    this.setList(droppableId, list);
  }

  @action
  onDragUpdate({ source, destination }) {
    this.isItemRemovable =
      !destination && source.droppableId === 'DROPPABLE_AREA_COPY_2';
  }

  @action
  onDragEnd({ source, destination }) {
    const lists = this.lists;
    if (source && destination) {
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
        const result = euiDragDropCopy(
          lists[sourceId],
          lists[destinationId],
          source,
          destination,
          {
            property: 'id',
            modifier: makeId
          }
        );
        this.setList(sourceId, result[sourceId]);
        this.setList(destinationId, result[destinationId]);
      }
    } else if (!destination && source.droppableId === 'DROPPABLE_AREA_COPY_2') {
      this.remove(source.droppableId, source.index);
    }
    this.isItemRemovable = false;
  }

  <template>
    <EuiDragDropContext
      @onDragEnd={{this.onDragEnd}}
      @onDragUpdate={{this.onDragUpdate}}
      as |dnd|
    >
      <EuiFlexGroup>
        <EuiFlexItem style='width: 50%;'>
          <dnd.Droppable
            @droppableId='DROPPABLE_AREA_COPY_1'
            @cloneDraggables={{true}}
            @spacing='l'
            @grow={{true}}
            as |list|
          >
            {{#each this.list1 key='id' as |item index|}}
              <list.Draggable @index={{index}} @draggableId={{item.id}} @spacing='l'>
                <EuiPanel>{{item.content}}</EuiPanel>
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiFlexItem>
        <EuiFlexItem style='width: 50%;'>
          <dnd.Droppable
            @droppableId='DROPPABLE_AREA_COPY_2'
            @withPanel={{true}}
            @grow={{true}}
            as |list|
          >
            {{#each this.list2 key='id' as |item index|}}
              <list.Draggable
                @index={{index}}
                @draggableId={{item.id}}
                @spacing='l'
                @isRemovable={{this.isItemRemovable}}
              >
                <EuiPanel>
                  <EuiFlexGroup @gutterSize='none' @alignItems='center'>
                    <EuiFlexItem>{{item.content}}</EuiFlexItem>
                    <EuiFlexItem @grow={{false}}>
                      {{#if this.isItemRemovable}}
                        <EuiIcon @type='trash' @color='danger' />
                      {{else}}
                        <EuiToolTip @content='Remove' @disableScreenReaderOutput={{true}}>
                          <EuiButtonIcon
                            @iconType='cross'
                            aria-label='Remove'
                            {{on 'click' (fn this.remove 'DROPPABLE_AREA_COPY_2' index)}}
                          />
                        </EuiToolTip>
                      {{/if}}
                    </EuiFlexItem>
                  </EuiFlexGroup>
                </EuiPanel>
              </list.Draggable>
            {{else}}
              <EuiFlexGroup
                @alignItems='center'
                @justifyContent='spaceAround'
                @gutterSize='none'
                style='height: 100%;'
              >
                <EuiFlexItem @grow={{false}}>Drop Items Here</EuiFlexItem>
              </EuiFlexGroup>
            {{/each}}
          </dnd.Droppable>
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiDragDropContext>
  </template>
}
```
