---
title: Drag and drop
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Drag and drop"/>
<EuiSpacer @size="l" />

<EuiText>

Lists whose items can be dragged to reorder them, or moved between
lists. `EuiDragDropContext` wraps the lists and reports each drop;
it yields `Droppable` (a list), which yields `Draggable` (an item).

```hbs
<EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
  <dnd.Droppable @droppableId="list" @spacing="m" as |list|>
    {{#each this.items key="id" as |item index|}}
      <list.Draggable @draggableId={{item.id}} @index={{index}} @spacing="m">
        <EuiPanel>{{item.label}}</EuiPanel>
      </list.Draggable>
    {{/each}}
  </dnd.Droppable>
</EuiDragDropContext>
```

```js
import { euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';

onDragEnd = ({ source, destination }) => {
  if (destination) {
    this.items = euiDragDropReorder(this.items, source.index, destination.index);
  }
};
```

You own the lists: `@onDragEnd` gets `{ draggableId, source, destination }`
(each `{ droppableId, index }`; `destination` is `null` when dropped
outside a list), and `euiDragDropReorder`, `euiDragDropMove` and
`euiDragDropCopy` compute the new lists.

Items can be dragged with the mouse (through Atlassian's
[pragmatic drag and drop](https://atlassian.design/components/pragmatic-drag-and-drop),
a dependency of `@ember-eui/core`) or the keyboard: focus an item, press
Space to lift it, the arrow keys to move it, Space to drop it and Escape
to cancel. Each context only reacts to its own items, so other pragmatic
drag and drop code on the page (e.g. your own `draggable()` modifiers)
does not interfere. Items only move between lists of the same `@type`;
`@isDropDisabled` and `@isDragDisabled` lock lists and items, and
`@cloneDraggables` makes a list of templates that are copied, not moved.

Dragging near an edge scrolls: the window (turn it off with
`@autoScrollWindow={{false}}` on the context), a list that scrolls itself
(`@autoScroll={{false}}` on the droppable turns it off), and any other
container you give the yielded modifier, e.g. a board of lists:
`<div class="board" &#123;&#123;dnd.autoScroll}}>`. Moving an item with the
keyboard keeps it in view.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiDragDropContext

Wraps lists whose items can be dragged to reorder them or to move them
between lists. It yields `{ Droppable }`; each droppable yields its
`Draggable`. You own the lists: update them in `@onDragEnd`, e.g. with
`euiDragDropReorder` from `@ember-eui/core/utils/drag-drop`.

Dragging with the pointer is handled by Atlassian's pragmatic drag and
drop; the keyboard (Space, arrows, Escape) by these components.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@onDragEnd` (required) | `(result: DropResult) => void` |  | Called with the result when an item is dropped (or the drag cancelled). |
| `@onDragStart` | `(start: DragStart) => void` |  | Called when a drag starts. |
| `@onDragUpdate` | `(update: DropResult) => void` |  | Called when the destination changes during a drag. |
| `@autoScrollWindow` | `boolean` | `true` | Scrolls the window while dragging near its edges. |

### EuiDroppable

A list items can be dragged within and dropped into (yielded as
`Droppable` by `EuiDragDropContext`). It yields `{ Draggable }` for its
items.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@droppableId` (required) | `string` |  | Unique id of the list, reported in `onDragEnd`. |
| `@type` | `string` | `'EUI_DEFAULT'` | Items can only move between lists of the same type. |
| `@direction` | `'vertical' \| 'horizontal'` | `'vertical'` | `'vertical'` or `'horizontal'` list. |
| `@isDropDisabled` | `boolean` |  | Nothing can be dropped here. |
| `@cloneDraggables` | `boolean` |  | Items dragged from here are copies: the list keeps its items (and nothing can be dropped here). |
| `@spacing` | `'none' \| 's' \| 'm' \| 'l'` | `'none'` | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@withPanel` | `boolean` |  | Panel look (background, padding, rounded corners). |
| `@grow` | `boolean` |  | Grows to fill its flex container. |
| `@autoScroll` | `boolean` | `true` | Scrolls the list while an item is dragged near its edges (when the list itself scrolls, e.g. with a max height). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiDraggable

An item of an `EuiDroppable` list (yielded as `Draggable`). Drag it with
the mouse, or focus it and press Space to lift it, the arrow keys to
move it and Space again to drop it (Escape cancels).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@draggableId` (required) | `string` |  | Unique id of the item, reported in `onDragEnd`. |
| `@index` (required) | `number` |  | Position of the item in its list. |
| `@isDragDisabled` | `boolean` |  | The item cannot be dragged. |
| `@customDragHandle` | `boolean` |  | Only a handle drags the item: put the yielded `dragHandle` modifier on it, e.g. `<EuiIcon @type="grab" {{item.dragHandle}} />`. |
| `@isRemovable` | `boolean` |  | Skips the drop animation, e.g. for items removed on drop. |
| `@spacing` | `'none' \| 's' \| 'm' \| 'l'` | `'none'` | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |

| Block | Description |
| --- | --- |
| default block | The item's content (one element, which gets the item classes); yields `{ isDragging, dragHandle }`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
