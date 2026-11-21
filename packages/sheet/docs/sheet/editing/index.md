---
title: Editing basics
order: 20
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: editing basics"/>
<EuiSpacer @size="l" />

<EuiText>

Typing, pasting, clearing and filling cells, and what the sheet sends
you for each: one change set through `@onChange`. A click selects a
cell, a second click (or Enter, F2, a double-click, typing) edits it.

## Cells and the editor

With no records (and not `@isLoading`) the sheet shows "No records" under
the grid; the add row stays the way to add one (`@messages` `noRecords`;
an `<:empty>` block replaces the message).
Holding the pointer near an edge of the grid, or past it, scrolls the
grid (faster the farther out) and the range follows.
Select and date cells show a ▾ or calendar button on the hovered or
selected cell; a click on it opens the editor. A click anywhere in a
checkbox cell toggles it. A custom type gets the same with `opener` (an
EUI icon type) and `onCellClick`.

A click on another cell saves the editor's text and closes it. So does
scrolling the grid so that the edited cell leaves the view; a scroll
that keeps it fully in view (the grid bringing a far column into view
when it is focused) moves the editor with it. In a select
editor, typing filters the options, ArrowUp and ArrowDown move, and
Enter, Tab or a click picks. Enter or Tab right after typing picks the
first match.

## Related

- [Keyboard and shortcuts](/docs/sheet/docs/sheet/editing/keyboard)
- [Undo and redo](/docs/sheet/docs/sheet/editing/undo-redo)
- [Your own store](/docs/sheet/docs/sheet/own-store): the change set in full
- [Ranges, copy and paste](/docs/sheet/docs/sheet/selection)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
