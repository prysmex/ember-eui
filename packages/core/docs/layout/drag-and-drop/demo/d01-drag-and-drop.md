---
order: 1
---

# Drag and drop

<EuiText>
  <p>
    An extension of <EuiLink @href="https://atlassian.design/components/pragmatic-drag-and-drop/about" @external={{true}}>Pragmatic drag and drop</EuiLink> with a built-in style opinions and an API modelled on <EuiLink @href="https://github.com/hello-pangea/dnd" @external={{true}}>@hello-pangea/dnd</EuiLink> (the library upstream EUI uses). Functionality results from 3 components working together:
  </p>
  <ul>
    <li><EuiCode>&lt;EuiDragDropContext /&gt;</EuiCode>: Section of your application containing the draggable elements and the drop targets.</li>
    <li><EuiCode>&lt;dnd.Droppable /&gt;</EuiCode> (<strong>EuiDroppable</strong>): Area into which items can be dropped. Contains one or more <strong>Draggable</strong>. It is yielded by the context.</li>
    <li><EuiCode>&lt;list.Draggable /&gt;</EuiCode> (<strong>EuiDraggable</strong>): Items that can be dragged. Must be part of a <strong>Droppable</strong>. It is yielded by the droppable.</li>
  </ul>
  <p>
    <strong>Consider your users and use case.</strong> Drag and drop is often less suitable than standard form inputs. It relies on spatial orientation, which can be difficult for screen reader users. Keyboard navigation typically does not afford the same nuanced manipulation as a mouse. Items can be moved with the keyboard (focus an item, press Space to lift it, the arrow keys to move it, Space to drop it and Escape to cancel), but carefully consider your users' context when choosing this pattern.
  </p>
  <h3>Just the facts</h3>
  <p>
    <strong>EuiDraggable</strong> makes very few assumptions about what content it contains. To give affordance to draggable elements and to ensure a consistent experience, child elements must be able to accept a border and drop shadow (automatically applied via CSS). No other style opinions are applied, however.
  </p>
  <p>
    Similarly, <strong>EuiDroppable</strong> must accept a background color overlay (automatically applied via CSS), but has no other restrictions.
  </p>
  <p>
    All <strong>EuiDragDropContext</strong> elements are discrete and isolated; <strong>Droppables</strong> and <strong>Draggables</strong> cannot be shared/transferred between instances. Also, <strong>EuiDragDropContexts</strong> cannot be nested. It is recommended that a single, high-level <strong>EuiDragDropContext</strong> is used and <strong>Droppables</strong> account for categorical and functional separation (see later examples).
  </p>
  <p>
    <strong>EuiDragDropContext</strong> handles all events but makes no assumptions about the result of a drop event. As such, the following event handlers are available:
  </p>
  <ul>
    <li><EuiCode>@onDragStart</EuiCode></li>
    <li><EuiCode>@onDragUpdate</EuiCode></li>
    <li><EuiCode>@onDragEnd</EuiCode> (required)</li>
  </ul>
  <p>
    EUI also provides methods (from <EuiCode>@ember-eui/core/utils/drag-drop</EuiCode>) for helping to deal to common action types:
  </p>
  <ul>
    <li><EuiCode>euiDragDropReorder</EuiCode>: change an item's location in a droppable area</li>
    <li><EuiCode>euiDragDropCopy</EuiCode>: create a duplicate of an item in a different droppable area</li>
    <li><EuiCode>euiDragDropMove</EuiCode>: move an item to a different droppable area</li>
  </ul>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiDragDropContext } from '@ember-eui/core/components';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class BareDemo extends Component {
  list = makeList(3);

  @action
  onDragEnd({ source, destination }) {
    console.log(source, destination);
  }

  <template>
    <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
      <dnd.Droppable @droppableId='DROPPABLE_AREA_BARE' as |list|>
        {{#each this.list key='id' as |item index|}}
          <list.Draggable @index={{index}} @draggableId={{item.id}}>
            <div>{{item.content}}</div>
          </list.Draggable>
        {{/each}}
      </dnd.Droppable>
    </EuiDragDropContext>
  </template>
}
```
