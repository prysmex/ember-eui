---
title: Table
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Table"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiTable` and its parts render EUI's table markup and styles: they only
produce HTML. Sorting, selection, filtering and pagination are yours to
compute, in the component or with a headless table library; these
components show the result.

```hbs
<EuiTable>
  <EuiTableHeader>
    <EuiTableHeaderCell>Name</EuiTableHeaderCell>
    <EuiTableHeaderCell @align="right">Size</EuiTableHeaderCell>
  </EuiTableHeader>
  <EuiTableBody>
    {{#each this.rows as |row|}}
      <EuiTableRow>
        <EuiTableRowCell>{{row.name}}</EuiTableRowCell>
        <EuiTableRowCell @align="right">{{row.size}}</EuiTableRowCell>
      </EuiTableRow>
    {{/each}}
  </EuiTableBody>
</EuiTable>
```

- **Header**: `EuiTableHeaderCell` sorts with `@onSort`, `@isSorted` and
  `@isSortAscending`; `EuiTableHeaderCellCheckbox` holds a "select all"
  checkbox; `EuiTableHeaderButton` is a plain button for a header.
- **Rows**: `EuiTableRow` (`@isSelected`, `@onClick`, `@hasActions`),
  `EuiTableRowCell` (`@align`, `@truncateText`, `@textOnly={{false}}` for
  components, `@showOnHover` for actions) and `EuiTableRowCellCheckbox`.
- **Footer**: `EuiTableFooter` with `EuiTableFooterCell`s.
- **Pagination**: `EuiTablePagination` shows the pages and a "Rows per
  page" menu.
- **Small screens**: a responsive table turns rows into cards; cells take
  `@mobileOptions` (`{ header, show, only, enlarge }`), and
  `EuiTableHeaderMobile` with `EuiTableSortMobile` replaces the header
  row there.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTable

A styled `<table>`, built from `EuiTableHeader`, `EuiTableHeaderCell`,
`EuiTableBody`, `EuiTableRow` and `EuiTableRowCell`. These components
only render the markup: sorting, selection and pagination stay yours
(or come from a headless table library).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@compressed` | `boolean` |  | Smaller text and padding. |
| `@tableLayout` | `'fixed' \| 'auto'` | `'fixed'` | `'fixed'` (columns share the width, text wraps or truncates) or `'auto'` (columns fit their content). |
| `@responsive` | `boolean` | `true` | On small screens, rows become cards. |

| Block | Description |
| --- | --- |
| default block | The header, body and footer. |

### EuiTableHeader

The `<thead>` of an `EuiTable`, with its row of `EuiTableHeaderCell`s.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@wrapWithTableRow` | `boolean` | `true` | Wraps the cells in a `<tr>`. |

| Block | Description |
| --- | --- |
| default block | The header cells (or rows, without `@wrapWithTableRow`). |

### EuiTableHeaderCell

A column header of an `EuiTable`. With `@onSort` it is a button that
shows the sort direction (`@isSorted`, `@isSortAscending`).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@align` | `TableAlignment` | `'left'` | `'left'`, `'right'` (numbers) or `'center'`. |
| `@onSort` | `(event: MouseEvent) => void` |  | Makes the header a button sorting the column. |
| `@isSorted` | `boolean` |  | The table is sorted by this column: shows the direction. |
| `@isSortAscending` | `boolean` |  | Ascending order (arrow up); descending otherwise. |
| `@readOnly` | `boolean` |  | Shows the sort state without the button. |
| `@width` | `number \| string` |  | Width, e.g. `100` (px) or `'20%'`. |
| `@description` | `string` |  | More about the column, in its title and for screen readers. |
| `@scope` | `string` | `'col'` | `scope` of the `<th>`. |
| `@mobileOptions` | `TableMobileOptions` |  | `{ show, only }` on small screens. |

| Block | Description |
| --- | --- |
| default block | The column's name. |

### EuiTableHeaderCellCheckbox

A header cell holding a checkbox, e.g. "select all rows".

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@width` | `number \| string` |  | Width, e.g. `32` (px). |
| `@scope` | `string` | `'col'` | `scope` of the `<th>`. |

| Block | Description |
| --- | --- |
| default block | The checkbox. |

### EuiTableHeaderButton

A button in a header cell, e.g. a column that opens a menu.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@iconType` |  |  | Icon after the text, any `EuiIcon` type. |

| Block | Description |
| --- | --- |
| default block | The text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

### EuiTableBody

The `<tbody>` of an `EuiTable`.

| Block | Description |
| --- | --- |
| default block | The `EuiTableRow`s. |

### EuiTableRow

A row of an `EuiTable` body.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isSelected` | `boolean` |  | Highlights the row as selected. |
| `@isSelectable` | `boolean` |  | The row has a selection checkbox. |
| `@hasActions` | `boolean` |  | The row has an actions cell (with `@hasActions` on the cell). |
| `@isExpandable` | `boolean` |  | The row can expand (it has an expander cell). |
| `@isExpandedRow` | `boolean` |  | The row is the expanded content of the previous row. |
| `@onClick` | `(event: Event) => void` |  | Makes the row clickable (also with Enter and Space). |

| Block | Description |
| --- | --- |
| default block | The cells. |

### EuiTableRowCell

A cell of an `EuiTableRow`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@align` | `TableAlignment` | `'left'` | `'left'`, `'right'` (numbers) or `'center'`. |
| `@truncateText` | `boolean` |  | Cuts long text with an ellipsis instead of wrapping it. |
| `@textOnly` | `boolean` | `true` | The content is only text (wrapped in a span that truncates or wraps). Set `false` for components. |
| `@setScopeRow` | `boolean` |  | Renders a `<th scope="row">`: the row's header. |
| `@showOnHover` | `boolean` |  | Shows the content only while the row is hovered. |
| `@hasActions` | `boolean` |  | The cell holds the row's actions. |
| `@isExpander` | `boolean` |  | The cell holds the row's expand button. |
| `@valign` | `'top' \| 'middle' \| 'bottom'` | `'middle'` | Vertical alignment: `'top'`, `'middle'` or `'bottom'`. |
| `@width` | `number \| string` |  | Width, e.g. `100` (px) or `'20%'`. |
| `@mobileOptions` | `TableMobileOptions` |  | On small screens: `{ show, only, header, enlarge, align, truncateText }`. `header` labels the value in the row's card; the `<:mobile>` block replaces the content there. |

| Block | Description |
| --- | --- |
| default block | The content. |
| `<:mobile>` | Different content on small screens. |

### EuiTableRowCellCheckbox

A row cell holding a checkbox, e.g. to select the row.

| Block | Description |
| --- | --- |
| default block | The checkbox. |

### EuiTableFooter

The `<tfoot>` of an `EuiTable`, with a row of `EuiTableFooterCell`s.

| Block | Description |
| --- | --- |
| default block | The footer cells. |

### EuiTableFooterCell

A cell of an `EuiTableFooter`, e.g. a column's total.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@align` | `TableAlignment` | `'left'` | `'left'`, `'right'` (numbers) or `'center'`. |
| `@width` | `number \| string` |  | Width, e.g. `100` (px) or `'20%'`. |

| Block | Description |
| --- | --- |
| default block | The content. |

### EuiTablePagination

The pagination under a table: a "Rows per page" menu on the left and
the page buttons on the right. You keep the page and the page size.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@activePage` | `number` |  | The current page, from `0`. |
| `@pageCount` | `number` |  | Number of pages. |
| `@onChangePage` | `(page: number) => void` |  | Called with the clicked page (from `0`). |
| `@itemsPerPage` | `number` | `50` | Rows per page. |
| `@itemsPerPageOptions` | `number[]` | `[10, 20, 50, 100]` | Choices of rows per page. |
| `@onChangeItemsPerPage` | `(itemsPerPage: number) => void` |  | Called with the chosen rows per page. |
| `@hidePerPageOptions` | `boolean` |  | Hides the "Rows per page" menu. |
| `@compressed` | `boolean` |  | Smaller page buttons. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<span>`.

### EuiTableHeaderMobile

A bar shown above a responsive `EuiTable` on small screens (where the
header row is hidden), e.g. with "select all" and `EuiTableSortMobile`.

| Block | Description |
| --- | --- |
| default block | The controls. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiTableSortMobile

A "Sorting" button opening a menu of the sortable columns, for small
screens where a responsive `EuiTable` hides its header. Usually in an
`EuiTableHeaderMobile`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@items` | `EuiTableSortMobileItemOption[]` |  | The sortable columns. |
| `@anchorPosition` |  | `'downRight'` | Where the menu opens. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiTableSortMobileItem

A column in the `EuiTableSortMobile` menu.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@onSort` | `(event: MouseEvent) => void` |  | Sorts by this column. |
| `@isSorted` | `boolean` |  | The table is sorted by this column. |
| `@isSortAscending` | `boolean` |  | Ascending order (arrow up); descending otherwise. |
| `@ariaLabel` | `string` |  | The column's name, for the accessible label (defaults to the text). |

| Block | Description |
| --- | --- |
| default block | The column's name. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

</EuiText>
<!-- api:end -->
