---
"@ember-eui/core": minor
---

Add the EUI 41 components that were missing, each with a docs page and tests:
EuiSuperSelect, EuiSelectable (and its templates), EuiSuggest, the color
components (EuiColorPicker, EuiColorPalettePicker, EuiColorStops, ...),
EuiTour, EuiResizableContainer, EuiRefreshInterval (EuiSuperDatePicker now
refreshes automatically), the table building blocks, and drag and drop
(EuiDragDropContext, EuiDroppable, EuiDraggable).

Drag and drop is built on Atlassian's pragmatic drag and drop, so
`@atlaskit/pragmatic-drag-and-drop` and its auto scroll package are new
dependencies (installed with core; nothing to add to the app).
