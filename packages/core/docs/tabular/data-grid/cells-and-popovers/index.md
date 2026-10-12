---
title: Data grid cells and popovers
order: 4
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid cells and popovers"/>
<EuiSpacer @size="l" />

<EuiText>

Hovering or focusing an expandable cell shows its actions; the last one
opens the expansion popover, which renders the cell again with
`isDetails` set (Enter or F2 opens it from the keyboard, Escape or F2
closes it and returns focus to the cell).

Column `cellActions` are components receiving `@rowIndex`, `@colIndex`,
`@columnId`, `@isExpanded` and the `@Component` button to render, or (an
Ember convenience) descriptors `{ iconType, label, onClick }`.
`visibleCellActions` (default 2) sets how many show on hover; the rest are
listed in the popover.

Customize the popover with `@renderCellPopover` or the `<:cellPopover>`
block. Columns with `isExpandable: false` have no popover; when such a
cell contains interactive elements, Enter moves focus into the cell (Tab
cycles through its contents) and Escape returns to the grid.

</EuiText>

<EuiHorizontalRule />
