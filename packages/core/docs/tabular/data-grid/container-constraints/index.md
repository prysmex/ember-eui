---
title: Data grid container constraints
order: 6
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid container constraints"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiDataGrid** adapts to its container: it hides toolbar controls when it
is narrow and, when its height or width is constrained (by `@height` /
`@width` or by its container), virtualizes its body so only the visible
cells are rendered. Without a height it grows to fit all rows of the current
page.

`@virtualizationOptions` tunes the virtualized body: `overscanRowCount` and
`overscanColumnCount` (extra rows and columns rendered outside the view, 1
by default), `estimatedRowHeight`, the `onItemsRendered` and `onScroll`
callbacks (with react-window's scroll directions and
`scrollUpdateWasRequested`), the scrolling element's `className` and
`style`, and `initialScrollTop` / `initialScrollLeft`. To scroll from
code, use `scrollTo` and `scrollToItem` from
[`@registerApi`](/docs/core/docs/tabular/data-grid/ref-methods).

Upstream virtualizes with react-window, and its other react-window options
(`estimatedColumnWidth`, `itemKey`, `outerElementType`, `direction`) don't
apply: the Ember body is its own virtualizer, which computes exact column
offsets, keys rows and cells by index and always renders a `div`. Without
`estimatedRowHeight` it also sizes the scrollable area exactly (react-window
estimates 50px for rows it hasn't laid out). To replace the virtualization
itself (another virtualization library, or rendering every row), use
[`@renderCustomGridBody`](/docs/core/docs/tabular/data-grid/custom-body-rendering):
it hands you the grid's cells, header and footer rows to lay out yourself.

</EuiText>

<EuiHorizontalRule />
