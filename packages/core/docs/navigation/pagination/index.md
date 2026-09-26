---
title: Pagination
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Pagination"/>

<EuiSpacer @size='l' />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPagination

Page numbers with previous/next buttons, for paged lists and tables.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@pageCount` | `number` | `1` | The total number of pages. |
| `@activePage` | `number` | `0` | The current page using a zero based index. So if you set the activePage to 1, it will activate the second page. |
| `@onPageClick` | `PageClickHandler` |  | Called with the clicked page's zero based index; update `@activePage` here. |
| `@compressed` | `boolean` |  | If true, will only show next/prev arrows instead of page numbers. |
| `@aria-controls` | `string` |  | If passed in, passes value through to each button to set aria-controls (the id of the content the pages change). |
| `@ariaControls` | `string` |  | Same as `'aria-controls'`. |

</EuiText>
<!-- api:end -->
