---
title: Data grid control columns
order: 7
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid control columns"/>
<EuiSpacer @size="l" />

<EuiText>

`@leadingControlColumns` and `@trailingControlColumns` add fixed-width
columns before and after the data columns, e.g. row selection or row
actions. Each is `{ id, width }` plus optional `headerCellRender`,
`rowCellRender` and `footerCellRender` components; without them the
`<:controlHeaderCell>`, `<:controlCell>` and `<:controlFooterCell>` blocks
render the column (switch on `columnId`). Control cells are not
expandable; their interactive contents are reached with Enter.

A footer row renders when `@renderFooterCellValue` or the `<:footerCell>`
block is given; it sticks to the bottom (`gridStyle.stickyFooter`) and is
styled by `gridStyle.footer`.

</EuiText>

<EuiHorizontalRule />
