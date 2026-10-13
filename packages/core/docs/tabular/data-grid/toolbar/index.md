---
title: Data grid toolbar
order: 4
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid toolbar"/>
<EuiSpacer @size="l" />

<EuiText>

The toolbar holds the column selector (search, show/hide and drag to
reorder), the sort popover (with `@sorting`), the keyboard shortcuts,
the display options (density and lines per row) and fullscreen. Hide it
with `@toolbarVisibility={{false}}` or toggle each control:

```hbs
<EuiDataGrid
  @toolbarVisibility={{hash
    showColumnSelector=(hash allowHide=true allowReorder=false)
    showDisplaySelector=(hash allowDensity=true allowRowHeight=false)
    showSortSelector=true
    showFullScreenSelector=false
    showKeyboardShortcuts=true
  }}
/>
```

Add your own controls with the `<:leftControlsPrepend>`,
`<:leftControlsAppend>` and `<:rightControls>` blocks;
`EuiDataGridToolbarControl` renders a toolbar-styled button with a count
badge. Below `@minSizeForControls` (479px) only the right controls show.

Additional controls can also be components in the options, like
upstream's `additionalControls`: one component (appended to the left
side) or `{ left: { prepend, append }, right }`. The display options
popover takes extra content with
`showDisplaySelector.additionalDisplaySettings` (a component), or a
completely custom layout with `showDisplaySelector.customRender`, a
component receiving `@densityControl`, `@rowHeightControl`,
`@additionalDisplaySettings` and `@resetButton`.

Control the visible columns with
`@columnVisibility={{hash visibleColumns=… setVisibleColumns=…}}`; the
order of `visibleColumns` is the display order.

## Reordering columns from the header

With `columnVisibility.canDragAndDropColumns`, header cells become drag
handles (with a drag icon): drag a header to another position, or focus
it, press **Space** to lift it, move it with the **Left/Right arrow**
keys and press **Space** again to drop it (**Escape** cancels). Focus
follows the dropped column. Columns can always be reordered from the
column selector and from the header actions ("Move left"/"Move right").

## Custom toolbar

Take over the toolbar layout with `@renderCustomToolbar` (a component) or
the `<:customToolbar>` block. Both receive the grid's controls as
components: `hasRoomForGridControls`, `columnControl`,
`columnSortingControl`, `keyboardShortcutsControl`, `displayControl` and
`fullScreenControl` (undefined when hidden by `@toolbarVisibility`), plus
`additionalControls` (the option components by position).

</EuiText>

<EuiHorizontalRule />
