---
order: 3
---

# Custom drag handle

<EuiText>
  <p>
    By default the entire element surface can initiate a drag. To specify an element within as the handle and create a containing group, set <EuiCode>@customDragHandle=&#123;&#123;true&#125;&#125;</EuiCode> and <EuiCode>@hasInteractiveChildren=&#123;&#123;true&#125;&#125;</EuiCode> on the <strong>Draggable</strong>.
  </p>
  <p>
    The object yielded by the <strong>Draggable</strong> block provides what is needed for functionality. Along with the <EuiCode>@customDragHandle</EuiCode> flag, the yielded <EuiCode>dragHandle</EuiCode> modifier needs to be added to the intended handle element.
  </p>
  <p>
    <strong>Accessibility requirement:</strong> <strong>Icon-only</strong> custom drag handles require an accessible label. Add an <EuiCode>aria-label="Drag handle"</EuiCode> attribute to your component or HTML element that receives the <EuiCode>dragHandle</EuiCode> modifier.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiDragDropContext, EuiFlexGroup, EuiFlexItem, EuiIcon, EuiPanel } from '@ember-eui/core/components';
import { euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class CustomHandleDemo extends Component {
  @tracked list = makeList(3);

  @action
  onDragEnd({ source, destination }) {
    if (source && destination) {
      this.list = euiDragDropReorder(this.list, source.index, destination.index);
    }
  }

  <template>
    <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
      <dnd.Droppable @droppableId='CUSTOM_HANDLE_DROPPABLE_AREA' @spacing='m' @withPanel={{true}} as |list|>
        {{#each this.list key='id' as |entry index|}}
          <list.Draggable
            @spacing='m'
            @index={{index}}
            @draggableId={{entry.id}}
            @customDragHandle={{true}}
            @hasInteractiveChildren={{true}}
            as |item|
          >
          <EuiPanel @paddingSize='s'>
            <EuiFlexGroup @alignItems='center' @gutterSize='s'>
              <EuiFlexItem @grow={{false}}>
                <EuiPanel
                  @color='transparent'
                  @paddingSize='s'
                  aria-label='Drag Handle'
                  {{item.dragHandle}}
                >
                  <EuiIcon @type='dragVertical' />
                </EuiPanel>
              </EuiFlexItem>
              <EuiFlexItem>{{entry.content}}</EuiFlexItem>
            </EuiFlexGroup>
          </EuiPanel>
          </list.Draggable>
        {{/each}}
      </dnd.Droppable>
    </EuiDragDropContext>
  </template>
}
```
