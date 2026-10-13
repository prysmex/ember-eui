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
by default), `onItemsRendered` and `onScroll` callbacks, the scrolling
element's `className` and `style`, and `initialScrollTop` /
`initialScrollLeft`. Upstream's react-window options (`estimatedRowHeight`,
`estimatedColumnWidth`, `itemKey`, `outerElementType`, `direction`) don't
apply: the Ember body measures rows and columns exactly. To scroll from
code, use `scrollTo` and `scrollToItem` from
[`@registerApi`](/docs/core/docs/tabular/data-grid/ref-methods); to replace
the virtualized body entirely, see
[custom body rendering](/docs/core/docs/tabular/data-grid/custom-body-rendering).

</EuiText>

<EuiHorizontalRule />
