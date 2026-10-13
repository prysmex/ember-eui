---
title: Table
order: 3
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Table"/>
<EuiSpacer @size="l" />

<EuiText>

If you need more custom behavior than either
[EuiBasicTable](../basic-table) or [EuiInMemoryTable](../in-memory-table)
allow, you can construct your own table from EUI's low-level building
blocks, like `EuiTableHeader` and `EuiTableRowCell`. They render EUI's
table markup and styles; there are several important caveats to keep in
mind:

- **Selection and filtering**: custom tables must completely handle their
  own selection and filtering (and sorting and pagination), in the
  component or with a headless table library.
- **Mobile headers**: pass a `mobileOptions.header` equivalent to the
  column header to each `EuiTableRowCell`, so the mobile (cards) layout
  uses it to label each cell. To add mobile support for selection and
  sorting, wrap them in `EuiTableHeaderMobile` and use `EuiTableSortMobile`
  for sorting. See the demo below.
- **Cell text behavior**: set `@truncateText={{true}}` on cells to enforce
  a single line and truncate their contents, or `@textOnly={{false}}` when
  the contents must be a direct descendant of the cell (components).

```hbs
<EuiTable>
  <EuiTableHeader>
    <EuiTableHeaderCell>Name</EuiTableHeaderCell>
    <EuiTableHeaderCell @align="right">Size</EuiTableHeaderCell>
  </EuiTableHeader>
  <EuiTableBody>
    {{#each this.rows as |row|}}
      <EuiTableRow>
        <EuiTableRowCell @mobileOptions={{hash header="Name"}}>{{row.name}}</EuiTableRowCell>
        <EuiTableRowCell @align="right" @mobileOptions={{hash header="Size"}}>{{row.size}}</EuiTableRowCell>
      </EuiTableRow>
    {{/each}}
  </EuiTableBody>
</EuiTable>
```

- **Header**: `EuiTableHeaderCell` sorts with `@onSort`, `@isSorted` and
  `@isSortAscending`; `EuiTableHeaderCellCheckbox` holds a "select all"
  checkbox; `EuiTableHeaderButton` is a plain button for a header.
- **Rows**: `EuiTableRow` (`@isSelected`, `@hasSelection`, `@onClick`,
  `@hasActions`, `@isExpandedRow`), `EuiTableRowCell` (`@align`,
  `@valign`, `@truncateText`, `@textOnly`, `@showOnHover`,
  `@mobileOptions`) and `EuiTableRowCellCheckbox`.
- **Footer**: `EuiTableFooter` with `EuiTableFooterCell`s.
- **Pagination**: `EuiTablePagination` shows the pages and a "Rows per
  page" menu.
- **Layout**: `EuiTable` takes `@tableLayout`, `@compressed`,
  `@responsiveBreakpoint` and `@scrollableInline`.

### Ember differences

Upstream's beta `stickyHeader` and `stickyScrollbar` props of `EuiTable`
are not supported yet.

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

Like upstream, the table is wrapped in a `div.euiTable__wrapper`;
attributes go to the `<table>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@css` | `EuiCss` |  | Extra styles composed last into the `<table>`'s class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |
| `@compressed` | `boolean` |  | Smaller text and padding (not applied to the cards layout). |
| `@tableLayout` | `'fixed' \| 'auto'` | `'fixed'` | `'fixed'` (columns share the width, text wraps or truncates) or `'auto'` (columns fit their content). |
| `@responsive` | `boolean` | `true`; `false` never collapses (same as `@responsiveBreakpoint={{false}}`) | Rows become cards below `@responsiveBreakpoint`. |
| `@responsiveBreakpoint` | `TableResponsiveBreakpoint` | `'m'` (upstream) | Named theme breakpoint below which rows become cards; `true` always renders cards, `false` never. Takes precedence over `@responsive`. |
| `@hasBackground` | `boolean` | `true` | The table's plain background. |
| `@scrollableInline` | `boolean` |  | Lets the table grow wider than its container and scroll inline. Use with `@tableLayout="auto"`. Upstream beta. |

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
shows the sort direction (`@isSorted`, `@isSortAscending`), or a
"sortable" icon while the column is not sorted.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@align` | `TableAlignment` | `'left'` | `'left'`, `'right'` (numbers) or `'center'`. |
| `@onSort` | `(event: MouseEvent) => void` |  | Makes the header a button sorting the column. |
| `@isSorted` | `boolean` |  | The table is sorted by this column: shows the direction. |
| `@isSortAscending` | `boolean` |  | Ascending order (arrow up); descending otherwise. |
| `@readOnly` | `boolean` |  | Shows the sort state without the button. |
| `@width` | `number \| string` |  | Width, e.g. `100` (px) or `'20%'`. |
| `@minWidth` | `number \| string` |  | Min width, e.g. `100` (px). |
| `@maxWidth` | `number \| string` |  | Max width, e.g. `'30%'`. |
| `@description` | `string` |  | More about the column, in its title and for screen readers. |
| `@scope` | `string` | `'col'` | `scope` of the `<th>`. |
| `@mobileOptions` | `TableMobileOptions` |  | `{ show, only }` for the cards layout. |
| `@tooltipProps` | `EuiTableHeaderCellTooltipProps` |  | Adds an icon with a tooltip next to the name. In a sortable header the icon is plain and the tooltip shows on the whole sort button. |

| Block | Description |
| --- | --- |
| default block | The column's name. |

### EuiTableHeaderCellCheckbox

A header cell holding a checkbox, e.g. "select all rows".

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@width` | `number \| string` | the theme's checkbox column width | Width, e.g. `32` (px). |
| `@minWidth` | `number \| string` |  | Min width, e.g. `32` (px). |
| `@maxWidth` | `number \| string` |  | Max width, e.g. `32` (px). |
| `@scope` | `string` | `'col'` | `scope` of the `<th>`. |

| Block | Description |
| --- | --- |
| default block | The checkbox. |

### EuiTableHeaderButton

A button in a header cell, e.g. a column that opens a menu. Upstream
removed this component; it uses the header sort button's styles
(full width, primary underline on hover and focus).

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
| `@isSelectable` | `boolean` |  | The row's selection checkbox is enabled. Also reserves the cards layout's checkbox column unless `@hasSelection` is given. |
| `@hasSelection` | `boolean` | `@isSelectable` | The table has a checkbox column (upstream): reserves room for it in the cards layout and lines expanded rows up with the second column. |
| `@hasActions` | `boolean \| 'custom'` |  | The row has an actions cell (with `@hasActions` on the cell): shows hover-only actions while the row is hovered; `true` reserves the cards layout's right column. |
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
| `@truncateText` | `boolean` |  | `true` cuts long text with an ellipsis; otherwise long words break (upstream default). |
| `@textOnly` | `boolean` | `true` | The content is only text (wrapped in a span that truncates or wraps). Set `false` for components. |
| `@setScopeRow` | `boolean` |  | Renders a `<th scope="row">`: the row's header. |
| `@showOnHover` | `boolean` |  | Shows the content only while the row is hovered or the cell has focus (always shown in the cards layout). Upstream's `euiBasicTableAction-showOnHover`. |
| `@hasActions` | `boolean \| 'custom'` |  | The cell holds the row's actions (`true`: icon actions in the cards layout's right column; `'custom'`: other content on its own line). |
| `@isExpander` | `boolean` |  | The cell holds the row's expand button. |
| `@valign` | `'top' \| 'middle' \| 'bottom' \| 'baseline'` | `'middle'` | Vertical alignment: `'top'`, `'middle'`, `'bottom'` or `'baseline'`. |
| `@width` | `number \| string` |  | Width, e.g. `100` (px) or `'20%'`. |
| `@minWidth` | `number \| string` |  | Min width, e.g. `100` (px). |
| `@maxWidth` | `number \| string` |  | Max width, e.g. `'30%'`. |
| `@mobileOptions` | `TableMobileOptions` |  | In the cards layout: `{ show, only, header, enlarge, align, truncateText, textOnly, width, minWidth, maxWidth }`. `header` labels the value in the row's card; the `<:mobile>` block replaces the content there. |

| Block | Description |
| --- | --- |
| default block | The content. |
| `<:mobile>` | Different content in the cards layout. |

### EuiTableRowCellCheckbox

A row cell holding a checkbox, e.g. to select the row. In the cards
layout it sits in the card's top left corner (give the row
`@hasSelection` or `@isSelectable` to reserve room for it).

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
| `@minWidth` | `number \| string` |  | Min width, e.g. `100` (px). |
| `@maxWidth` | `number \| string` |  | Max width, e.g. `'30%'`. |

| Block | Description |
| --- | --- |
| default block | The content (truncated to one line, as upstream). |

### EuiTablePagination

The pagination under a table: a "Rows per page" menu on the left and
the page buttons on the right. You keep the page and the page size.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@activePage` | `number` |  | The current page, from `0`. |
| `@pageCount` | `number` |  | Number of pages. |
| `@onChangePage` | `(page: number) => void` |  | Called with the clicked page (from `0`). |
| `@itemsPerPage` | `number` | `10` (upstream) | Rows per page. `0` means all rows: the menu reads "Showing all rows" and the pages are hidden. |
| `@itemsPerPageOptions` | `number[]` | `[10, 25, 50]` (upstream) | Choices of rows per page. `0` is the "Show all rows" choice. |
| `@onChangeItemsPerPage` | `(itemsPerPage: number) => void` |  | Called with the chosen rows per page. |
| `@showPerPageOptions` | `boolean` | `true` | Shows the "Rows per page" menu. |
| `@compressed` | `boolean` |  | Passed to `EuiPagination`: "page of total" with arrows. |
| `@responsive` |  |  | Passed to `EuiPagination`: breakpoints at which it is compressed. |
| `@ariaControls` | `string` |  | Passed to `EuiPagination`: id of the content the pages change. |
| `@aria-label` | `string` |  | Accessible name of the pagination navigation (upstream `aria-label`), e.g. "Pagination for table: Users". |
| `@aria-labelledby` | `string` |  | Id of the element naming the pagination navigation. |

Deprecated: `@hidePerPageOptions` (Use `@showPerPageOptions={{false}}`. Hides the menu.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<span>`.

### EuiTableHeaderMobile

A bar shown above a responsive `EuiTable` on small screens (where the
header row is hidden), e.g. with "select all" and `EuiTableSortMobile`.
Like upstream it renders nothing while the table is not in cards.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@responsiveBreakpoint` | `TableResponsiveBreakpoint` | `'m'` | Same as the table's `@responsiveBreakpoint`: shown below this named theme breakpoint, always with `true`, never with `false`. |

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
