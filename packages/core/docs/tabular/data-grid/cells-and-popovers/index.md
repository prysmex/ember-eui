---
title: Data grid cells & popovers
order: 3
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid cells & popovers"/>
<EuiSpacer @size="l" />

<EuiText>

Data grid cells are rendered with the `<:cell as |cell|>` block or the
`@renderCellValue` component. Both receive cell-specific values (`rowIndex`,
`colIndex`, `columnId`, `schema`, `isDetails`, `setCellProps`,
`cellContext`, …) and can render anything from a string to other
components.

Each data grid cell automatically renders an expand action button and an
expansion popover (which can be disabled, see "Disabling cell expansion
popovers" below).
For cells with overflowing or truncated content, the expansion popover
displays the full content, or can be customized to show extra details.

## Copying cell values

When a data cell is focused and no text is selected, **Ctrl/Cmd+C** copies
the cell's visible text. If you have selected text, that selection is
copied instead. Control columns are skipped.

This copies the rendered text, not a raw data value. Copying a selection
across several cells (for example **Ctrl/Cmd+A** then **Ctrl/Cmd+C**) puts
tab and newline separated text on the clipboard, ready to paste into a
spreadsheet; control columns and screen reader text are left out.

To open, close or focus cells programmatically, see the
[ref methods](/docs/core/docs/tabular/data-grid/ref-methods) page.

</EuiText>

<EuiHorizontalRule />
