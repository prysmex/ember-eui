---
title: Data grid custom body rendering
order: 8
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid custom body rendering"/>
<EuiSpacer @size="l" />

<EuiText>

For **extremely** advanced use cases, the `@renderCustomGridBody` argument
(a component) or the `<:customGridBody>` block may be used to take complete
control over rendering the grid body. This may be useful for scenarios
where the default
[virtualized](/docs/core/docs/tabular/data-grid/container-constraints)
rendering is not desired, or where custom row layouts (e.g., the
conditional row details cell below) are required.

</EuiText>

<EuiSpacer />

<div>
<EuiCallOut @title="Warning" @color="warning" @iconType="warning">
    This argument is meant to be an <strong>escape hatch</strong>, and should
    only be used if you know exactly what you are doing. Once a custom
    renderer is used, you are in charge of ensuring the grid has all the
    correct semantic and aria labels required by the
    <EuiLink @href="https://www.w3.org/WAI/ARIA/apg/patterns/grid" @target="_blank">data grid spec</EuiLink>,
    and that keyboard focus and navigation still work in an accessible manner.
</EuiCallOut>
</div>

<EuiSpacer />

<EuiText>

The custom body receives:

- `Cell`: the grid cell component. Pass `@colIndex` and `@visibleRowIndex`
  (the row on the current page); optionally `@isExpandable` or
  `@renderCellValue` overrides. Its content comes from the grid's
  `@renderCellValue` and the control columns' `rowCellRender`, or from the
  `Cell`'s own block (the grid's `<:cell>` and `<:controlCell>` blocks can't
  reach a custom body, so use components as below).
- `visibleColumns` (control and data columns in display order) and
  `visibleRowData` (`startRow`, `endRow`, `visibleRowCount`) to follow
  column changes, sorting and pagination.
- `headerRow` and `footerRow` components to render (undefined when there is
  no header or footer).
- `setCustomGridBodyProps` to set attributes, `className`, `style` or
  `on*` listeners on the body's wrapping element (upstream's `ref` is not
  supported: use your own elements and modifiers), and `gridWidth`.

Keyboard navigation, cell expansion and focus work as in the default body.

</EuiText>

<EuiHorizontalRule />
