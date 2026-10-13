---
order: 4
---

# Interactive elements

<EuiText>
  <p>
    <strong>EuiDraggable</strong> can contain interactive elements such as buttons and form fields. Interactive elements require <EuiCode>@customDragHandle=&#123;&#123;true&#125;&#125;</EuiCode> and <EuiCode>@hasInteractiveChildren=&#123;&#123;true&#125;&#125;</EuiCode> on the <strong>Draggable</strong>. These args will maintain drag functionality and accessibility, while enabling click, keypress, etc., events on the interactive child elements.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiDragDropContext, EuiFlexGroup, EuiFlexItem, EuiIcon, EuiPanel } from '@ember-eui/core/components';
import { euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class InteractiveElementsDemo extends Component {
  @tracked list = makeList(3);

  @action
  noop() {}

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
              <EuiFlexItem @grow={{true}}>
                <EuiButton @fullWidth={{true}} {{on 'click' this.noop}}>
                  {{entry.content}}
                </EuiButton>
              </EuiFlexItem>
            </EuiFlexGroup>
          </EuiPanel>
          </list.Draggable>
        {{/each}}
      </dnd.Droppable>
    </EuiDragDropContext>
  </template>
}
```
