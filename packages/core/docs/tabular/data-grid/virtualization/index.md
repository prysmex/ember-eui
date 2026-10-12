---
title: Data grid virtualization
order: 5
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid virtualization"/>
<EuiSpacer @size="l" />

<EuiText>

The grid body is virtualized: only the rows and columns in view (plus a
few overscan rows and columns, see `@virtualizationOptions`) are rendered,
and scrolling only re-renders when the visible range changes. Give the grid
a `@height` (or put it in a container with a height) to make it scroll;
without one it grows to fit all rows of the current page.

`@virtualizationOptions` also reports `onItemsRendered` (rendered and
visible row/column ranges) and `onScroll` (positions and whether the grid
is scrolled to an edge).

</EuiText>

<EuiHorizontalRule />
