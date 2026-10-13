---
title: Resizable container
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Resizable container"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiResizableContainer` lays out panels side by side (or stacked) with a
draggable separator between them, like an editor with a sidebar. It
yields `{ Panel, Button, togglePanel }`: alternate panels and buttons as
its direct children.

```hbs
<EuiResizableContainer style="height: 300px;" as |c|>
  <c.Panel @initialSize={{25}} @minSize="15%">Sidebar</c.Panel>
  <c.Button />
  <c.Panel @initialSize={{75}}>Editor</c.Panel>
</EuiResizableContainer>
```

Sizes are percentages of the container. Drag a button (or focus it and
use the arrow keys) to resize the panels next to it; `@minSize` (`'20%'`
or `'200px'`) stops a panel from getting smaller.

- `@direction="vertical"` stacks the panels; give the container a height.
- `@mode="collapsible"` on a panel (next to a `@mode="main"` one) adds a
  button that collapses it; `togglePanel(id, { direction })` does the same
  from elsewhere.
- For controlled sizes, set `@size` on the panels and update it from
  `@onPanelWidthChange`, which gets `{ [panelId]: percent }`.
- `EuiResizableButton` also works on its own, outside a container: pass
  `@isHorizontal` and attach your own `{{on "mousedown"}}`,
  `{{on "touchstart"}}` and `{{on "keydown"}}` modifiers (see "Custom resize
  logic").

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiResizableContainer

Panels separated by draggable resize buttons, side by side
(`'horizontal'`) or stacked (`'vertical'`), like an IDE's sidebar and
editor. It yields `{ Panel, Button, togglePanel }`: alternate
`<c.Panel>`s and `<c.Button />`s as its direct children. Panels can be
collapsible (`@mode="collapsible"` next to a `@mode="main"` one).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@direction` | `'horizontal' \| 'vertical'` | `'horizontal'` | `'horizontal'` (side by side) or `'vertical'` (stacked). |
| `@onPanelWidthChange` | `(sizes: Record<string, number>) => void` |  | Called with every panel's size (`{ [panelId]: percent }`) after a change. |
| `@onToggleCollapsed` |  |  | Called when a panel is collapsed or expanded. |
| `@onResizeStart` | `(trigger: ResizeTrigger) => void` |  | Called when a resize starts: `'pointer'` when a button is pressed, `'key'` when an arrow key goes down on a focused button. |
| `@onResizeEnd` | `() => void` |  | Called when that resize ends: the pointer is released (or leaves the container), the arrow key is released, or the button loses focus. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiResizablePanel

A panel of an `EuiResizableContainer` (yielded as `Panel`), sized in
percent of the container.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the panel, e.g. to toggle it. |
| `@initialSize` | `number` |  | Starting size in percent of the container. |
| `@size` | `number` |  | Controlled size in percent (update it from `@onPanelWidthChange`). |
| `@minSize` | `string` | `'0px'` | Smallest size, e.g. `'20%'` or `'200px'`. |
| `@scrollable` | `boolean` | `true` | Scrolls its content when it overflows. |
| `@mode` | `Mode` |  | `'collapsible'` (with a toggle button, next to a `'main'` panel), `'main'`, or `['collapsible', { position, className, 'data-test-subj' }]` to place the toggle (`'top'`, `'middle'`, `'bottom'`) and to give it a class and a `data-test-subj`. |
| `@paddingSize` | `'none' \| 's' \| 'm' \| 'l'` | `'m'` | Padding inside the panel: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@wrapperPadding` | `'none' \| 's' \| 'm' \| 'l'` | `'none'` | Padding around the panel: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@color` |  | `'transparent'` | Background, any `EuiPanel` color. |
| `@hasShadow` | `boolean` | `false` | Adds a shadow (when there is no border). |
| `@hasBorder` | `boolean` | `false` | Adds a border, like `EuiPanel`'s (whose own default is `true`). |
| `@borderRadius` |  | `'none'` | `'none'` or `'m'` rounded corners. |

| Block | Description |
| --- | --- |
| default block | The panel's content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiResizableButton

The draggable separator between two panels of an
`EuiResizableContainer` (yielded as `Button`). Drag it, or focus it and
use the arrow keys.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the button. |
| `@disabled` | `boolean` |  | Disables resizing at this button (a disabled button is hidden, as upstream). |
| `@indicator` | `'handle' \| 'border'` | `'handle'` | The resize indicator: `'handle'` (two short grab lines that grow into one line on hover and focus) or `'border'` (a full-length 1px line). |
| `@alignIndicator` | `'center' \| 'start' \| 'end'` | `'center'` | Where the `'handle'` indicator sits along the button: `'center'`, `'start'` or `'end'`. |
| `@accountForScrollbars` | `'before' \| 'after' \| 'both'` |  | The button overlaps its neighbours by half its size on both sides by default, so it takes no room. When a panel shows a scrollbar next to it, `'before'`, `'after'` or `'both'` keep it from covering it. |
| `@isHorizontal` | `boolean` |  | Standalone use (outside an `EuiResizableContainer`): `true` for a horizontal (x-axis) resizer, otherwise vertical. Inside a container its direction is used. Attach your own `{{on "mousedown" …}}`, `{{on "touchstart" …}}` and `{{on "keydown" …}}` modifiers (upstream's `onMouseDown`, `onTouchStart` and `onKeyDown` props). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

</EuiText>
<!-- api:end -->
