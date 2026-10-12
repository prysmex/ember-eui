---
title: Data grid toolbar
order: 3
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

Control the visible columns with
`@columnVisibility={{hash visibleColumns=… setVisibleColumns=…}}`; the
order of `visibleColumns` is the display order.

</EuiText>

<EuiHorizontalRule />
