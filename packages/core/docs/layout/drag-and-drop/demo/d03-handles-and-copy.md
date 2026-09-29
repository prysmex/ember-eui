---
order: 3
---

# Drag handles and copies

<EuiText>

With `@customDragHandle` only the grab icon drags the item (put the
yielded `dragHandle` modifier on it), so the field inside stays usable.
The palette on the left has `@cloneDraggables`: its items are copied into
the form with `euiDragDropCopy`.

</EuiText>

```hbs template
<EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
  <EuiFlexGroup>
    <EuiFlexItem @grow={{false}} style="width: 180px;">
      <dnd.Droppable @droppableId="palette" @spacing="s" @cloneDraggables={{true}} as |list|>
        {{#each this.palette key="id" as |field index|}}
          <list.Draggable @draggableId={{field.id}} @index={{index}} @spacing="s">
            <EuiPanel @paddingSize="s" @color="subdued">{{field.label}}</EuiPanel>
          </list.Draggable>
        {{/each}}
      </dnd.Droppable>
    </EuiFlexItem>
    <EuiFlexItem>
      <dnd.Droppable @droppableId="form" @spacing="m" @withPanel={{true}} @grow={{true}} as |list|>
        {{#each this.form key="id" as |field index|}}
          <list.Draggable
            @draggableId={{field.id}}
            @index={{index}}
            @spacing="m"
            @customDragHandle={{true}}
            as |item|
          >
            <EuiPanel @paddingSize="s">
              <EuiFlexGroup @gutterSize="s" @alignItems="center" @responsive={{false}}>
                <EuiFlexItem @grow={{false}}>
                  <EuiIcon @type="grab" aria-label="Drag to reorder" {{item.dragHandle}} />
                </EuiFlexItem>
                <EuiFlexItem>
                  <EuiFieldText @compressed={{true}} @placeholder={{field.label}} aria-label={{field.label}} />
                </EuiFlexItem>
              </EuiFlexGroup>
            </EuiPanel>
          </list.Draggable>
        {{else}}
          <EuiText @size="s" @color="subdued"><p>Drag fields here.</p></EuiText>
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

import { euiDragDropCopy, euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';

let nextId = 0;

export default class HandlesAndCopy extends Component {
  palette = [
    { id: 'name', label: 'Name' },
    { id: 'email', label: 'Email' },
    { id: 'phone', label: 'Phone' },
  ];

  @tracked form = [{ id: 'form-name', label: 'Name' }];

  @action
  onDragEnd({ source, destination }) {
    if (!destination) return;

    if (source.droppableId === 'form') {
      this.form = euiDragDropReorder(this.form, source.index, destination.index);
    } else {
      this.form = euiDragDropCopy(this.palette, this.form, source, destination, {
        property: 'id',
        modifier: () => `field-${++nextId}`,
      }).form;
    }
  }
}
```
