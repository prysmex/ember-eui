---
title: Data grid cells and popovers
order: 4
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid cells and popovers"/>
<EuiSpacer @size="l" />

<EuiText>

## Expanding a cell

When you hover or focus an expandable cell, a small blue button with a
"maximize" icon (`euiDataGridCellExpandButton`) appears at its inline end.
It opens the **cell expansion popover**: the cell rendered again with
`isDetails: true`, so long or truncated values can be read in full, with
the column's cell actions listed below it. From the keyboard, focus the
cell and press **Enter** or **F2** to open the same popover; **Escape** or
**F2** closes it and returns focus to the cell. The cell's screen reader
description ends with "Press the Enter key to expand this cell" whenever
the button is available.

- Every data column is expandable by default. Set `isExpandable: false`
  on a column (or `setCellProps({ isExpandable: false })` from a cell, or
  `@isExpandable={{false}}` on a custom body `Cell`) to remove the button
  and the popover.
- A column with `cellActions` is always expandable, so keyboard and screen
  reader users can reach its actions.

## Cell actions

Column `cellActions` add buttons next to the expand button on hover and
focus. They are components receiving `@rowIndex`, `@colIndex`, `@columnId`,
`@isExpanded` and the `@Component` button to render (an icon button in the
cell, an empty button in the popover), or (an Ember convenience)
descriptors `{ iconType, label, onClick }`. `visibleCellActions` (default
2) sets how many show in the cell; the rest are only listed in the popover.

## Custom popovers

Customize the popover with `@renderCellPopover` or the `<:cellPopover>`
block. Both receive `rowIndex`, `colIndex`, `columnId`, `schema`,
`cellContentsElement` (the rendered cell content element),
`setCellPopoverProps` (popover options such as `panelClassName`),
`cellActions` (the default actions footer) and `DefaultCellPopover` (the
standard display, to fall back to it for some columns). A
`@renderCellPopover` component's default block renders the cell value
again with `isDetails`.

## Editing cells

Like upstream EUI, the grid has no built-in editing: render a form in the
cell popover that updates your data, as in the "Editable cells" demo
below. Pair it with `@registerApi` to close the popover and return focus
to the cell after saving.

## Interactive cells

Columns with `isExpandable: false` have no popover; when such a cell
contains interactive elements, Enter moves focus into the cell (Tab cycles
through its contents) and Escape returns to the grid.

## Imperative API

`@registerApi` is called after render with the grid's API (upstream's
`ref`): `setIsFullScreen(isFullScreen)`, `setFocusedCell({ rowIndex,
colIndex })`, `openCellPopover({ rowIndex, colIndex })`,
`closeCellPopover()`, `scrollTo({ scrollTop, scrollLeft })` and
`scrollToItem({ rowIndex, columnIndex, align })`. `rowIndex` is the row
of your data: the grid maps it through sorting and changes page when
needed (invalid cells throw). Restore focus with `setFocusedCell` after
closing a modal or flyout the grid opened.

## Copying

Copying a selection across cells (e.g. Ctrl/Cmd+A then Ctrl/Cmd+C) puts
tab and newline separated text on the clipboard, ready to paste into a
spreadsheet; control columns and screen reader text are left out. With
nothing selected, Ctrl/Cmd+C copies the focused cell's value.

</EuiText>

<EuiHorizontalRule />
