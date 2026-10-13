---
title: Data grid container constraints
order: 6
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid container constraints"/>
<EuiSpacer @size="l" />

<EuiText>

The grid body is virtualized: only the rows and columns in view (plus a
few overscan rows and columns, see `@virtualizationOptions`) are rendered,
and scrolling only re-renders when the visible range changes. Give the grid
a `@height` (or put it in a container with a height) to make it scroll;
without one it grows to fit all rows of the current page.

`@virtualizationOptions` also reports `onItemsRendered` (rendered and
visible row/column ranges) and `onScroll` (positions and whether the grid
is scrolled to an edge), and sets the scrolling element's `className` and
`style` and its `initialScrollTop`/`initialScrollLeft`. Scroll from code
with the `scrollTo` and `scrollToItem` methods of `@registerApi`.

## Layout shift compensation

Rows above the viewport can change height while you read further down,
e.g. when `auto` height rows finish measuring or `rowHeights` change.
`@rowHeightsOptions={{hash scrollAnchorRow="start"}}` (or `"center"`)
keeps the first (or middle) visible row where it is by scrolling the grid
by the same amount.

## Custom grid body

`@renderCustomGridBody` (a component) or the `<:customGridBody>` block
replace the virtualized body, an escape hatch for very custom layouts.
They receive:

- `Cell`: the grid cell component. Pass `@colIndex` and `@visibleRowIndex`
  (the row on the current page); optionally `@isExpandable` or
  `@renderCellValue` overrides. Its content comes from the grid's
  `@renderCellValue` or from the `Cell`'s own block (the grid's `<:cell>`
  block can't reach a custom body).
- `visibleColumns` (control and data columns in display order) and
  `visibleRowData` (`startRow`, `endRow`, `visibleRowCount`) to follow
  column changes, sorting and pagination.
- `headerRow` and `footerRow` components to render (undefined when there is
  no header or footer).
- `setCustomGridBodyProps` to set attributes, `className`, `style` or
  `on*` listeners on the body's wrapping element, and `gridWidth`.

Keyboard navigation, cell expansion and focus work as in the default body.

</EuiText>

<EuiHorizontalRule />
