---
title: Data grid ref methods
order: 7
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid ref methods"/>
<EuiSpacer @size="l" />

<EuiText>

For advanced use cases, and particularly for data grids that manage
associated modals/flyouts and need to manually control their grid cell
popovers & focus states, we expose certain internal methods. Upstream EUI
hands them out through the `ref` prop; in Ember, **EuiDataGrid** calls
`@registerApi` with them after render (like `EuiComboBox @registerApi`).
These methods are:

- `setIsFullScreen(isFullScreen)` - controls the fullscreen state of the
  data grid. Accepts a true/false boolean flag.
- `setFocusedCell({ rowIndex, colIndex })` - focuses the specified cell in
  the grid.
- `openCellPopover({ rowIndex, colIndex })` - opens the specified cell's
  popover contents.
- `closeCellPopover()` - closes any currently open cell popover.

<EuiCallOut @title="Accessibility warning regarding setFocusedCell" @color="warning" @iconType="warning">
  <:body>
    If your data grid toggles a modal or flyout, using <EuiCode>setFocusedCell</EuiCode> is
    an <strong>accessibility requirement</strong>. Your modal or flyout should
    restore focus into the grid on close to prevent keyboard or screen
    reader users from being stranded.
  </:body>
</EuiCallOut>

When using `setFocusedCell` or `openCellPopover`, keep in mind:

- `colIndex` is affected by the user reordering or hiding columns.
- If the passed cell indices are outside the data grid's total row count
  or visible column count, an error will be thrown.
- If the data grid is paginated or sorted, the grid will handle
  automatically finding specified row index's correct location for you.

In Ember, `setFocusedCell` always moves focus, even when the cell already
is the grid's focused cell (upstream skips that case), so focus can be
restored after a modal or popover closes.

### Scrolling methods

Upstream's `ref` also exposes react-window's `VariableSizeGrid` scrolling
methods. The Ember grid has its own virtualizer and ports their semantics:

- `scrollTo({ scrollLeft, scrollTop })` - scrolls the grid to the
  specified horizontal and vertical pixel offsets.
- `scrollToItem({ align = "auto", columnIndex, rowIndex })` - scrolls the
  grid to the specified row and column indices (`align` is `auto`,
  `smart`, `center`, `end` or `start`).

Unlike the methods above, `rowIndex` here refers to the **visible**
`rowIndex`. For example, `scrollToItem({ rowIndex: 50, columnIndex: 0 })`
will always scroll to the 51st visible row on the currently visible page,
regardless of the content in the cell. In contrast,
`setFocusedCell({ rowIndex: 50, colIndex: 0 })` will scroll to the 51st row
in your data, which may not be the 51st visible row in the grid if it is
paginated or sorted.

The below example shows how to use the internal APIs for a data grid that
opens a modal via cell actions, that scroll to specific cells, and that can
be put into full-screen mode.

</EuiText>

<EuiHorizontalRule />
