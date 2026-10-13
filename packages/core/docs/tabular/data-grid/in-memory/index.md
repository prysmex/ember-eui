---
title: Data grid in-memory
order: 9
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid in-memory"/>
<EuiSpacer @size="l" />

<EuiText>

`@pagination` (`{ pageIndex, pageSize, pageSizeOptions, onChangePage,
onChangeItemsPerPage }`) renders `EuiTablePagination` below the grid and
limits the rows to the current page. Page Up / Page Down change pages from
the keyboard, and the grid's accessible name reports the page. Pagination
is hidden when all rows fit in the smallest page size.

</EuiText>

<EuiHorizontalRule />
