---
title: Keyboard and shortcuts
order: 21
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: keyboard and shortcuts"/>
<EuiSpacer @size="l" />

<EuiText>

Every key on a cell, in an editor, on a header, a group header and a row
number; the shortcut list (Ctrl/Cmd+/); and typing with dead keys and
IMEs.

## Keyboard

| Key | On a cell | In an editor |
| --- | --- | --- |
| Arrows; Home, End (row start, end); Ctrl+Home, Ctrl+End (first, last cell) | Move (the grid's keys). Home and Ctrl+Home go to the first field; ArrowLeft from it reaches the row number | Move in the text |
| Ctrl/Cmd+arrows | Jump to the edge of the data, as in Excel: to the last filled cell of a block, else to the next filled cell, else to the last cell. With Shift, extend the range to it | Move in the text |
| PageUp, PageDown | Move by the rows in view (with Shift, extend the range) | |
| Shift+arrows, Shift+click, a mouse drag | Select a range: its far corner moves, the active cell (where the range started) keeps focus | Move in the text |
| Shift+Home, Shift+End; Ctrl/Cmd+Shift+Home, Ctrl/Cmd+Shift+End | Extend the range to the row's first or last field; to the first or the last record's last cell | Select text |
| Ctrl/Cmd+A | Select every cell | Select the text |
| A printable key | Opens the editor with that character. A date opens only on a digit; a checkbox has no editor. | Types |
| Enter, F2, double-click | Opens the editor on the current value (a date: the browser's date input) | Enter saves and goes down |
| Tab, Shift+Tab | Tab moves focus out of the grid, to the next element on the page | Save and go right / left |
| Escape | Ends the dashed mark of a copy; collapses a range to the active cell | Closes without saving |
| Space | Toggles a checkbox; presses a button; elsewhere expands the record | Types |
| Enter, Space on a button cell | Presses it (no editor) | |
| Alt+Shift+ArrowUp, Alt+Shift+ArrowDown (on a row number, or with whole rows selected) | With `@canMove`: moves the rows one record up or down | |
| A digit | Sets a rating | |
| Shift+Enter | Adds a record below and goes to it (without inserting: as Enter) | Saves and goes down; in long text, adds a line (also Alt+Enter) |
| Shift+F10, ContextMenu | Opens the row menu | |
| Delete, Backspace | Clear the selected range | Delete text |
| Ctrl/Cmd+C, Ctrl/Cmd+V | Copy / paste the range as tab-separated text (a cell with a tab or a line break is quoted, as Excel does) | The input's own |
| Ctrl/Cmd+X | Cut: copies the range, then clears it (one undo step; with `@readOnly` it only copies) | The input's own |
| Ctrl/Cmd+D | Fill down: the top row of the range into the cells below it; on one row, the row above into it | The browser's |
| Ctrl/Cmd+R | Fill right: the left column of the range into the cells right of it; on one column, the column to its left into it. Taken from the browser's reload while a cell has focus | The browser's |
| Ctrl/Cmd+Z; Ctrl/Cmd+Shift+Z, Ctrl+Y | Undo; redo | The input's own |
| Ctrl/Cmd+/ | Opens the shortcut list | |

Ctrl/Cmd+/ on a cell, a row number or a header opens the shortcut list:
every key of this table, by section, without the rows of features that
are off (`@readOnly`, `@canInsert`, row numbers, column drag,
`@canMove`). Escape
closes it and focus goes back to the cell. Its texts are messages
(`euiSheet.shortcuts`, `euiSheet.shortcutFillDown`, key names such as
`euiSheet.shortcutKeyEnter`), so `@messages` and `eui-i18n` translate it.
`?` is not a shortcut: it is a printable key and opens the editor.

On a header: Enter opens the header menu, and Space lifts the column to
move it with the arrows (Space drops it, Escape cancels).

On a group header ([Group by](/docs/sheet/docs/sheet/data/record-groups#group-by)): Enter and Space collapse or expand
it (with `@onGroupToggle`), the arrows go on through it, and nothing
else is taken.

On a row number: Space toggles the checkbox, Enter expands the record,
Shift+ArrowUp/Down selects rows, PageUp/PageDown move by the rows in view
(Shift selects them), Shift+F10 opens the menu, and Delete
clears the selected rows. Reached with the arrows, a row number has no
selection, so Delete, copy and paste do nothing there. On the add row,
Enter adds a record; typing, Space and Delete do nothing. On the
row-number column's header: Space or Enter checks every record, or none
when all are checked, as a click on its checkbox does; a screen reader
hears "Row number" and "Select all rows", "Some rows checked" or "All
rows checked".

## IME and dead keys

A composition starts in a hidden input over the cell: with a dead key
(`´` then `e` on a Spanish or Mac keyboard) or an IME (Japanese,
Pinyin), typing on a cell opens the editor with the composed text (`é`,
`日本`), not with the first key. Escape during it returns to the cell.
Inside an open editor, the Enter that confirms a composition is the
IME's: it does not save. This was checked with synthetic events only;
real IMEs and dead keys on macOS (Chrome, Safari, Firefox) are still to
be tried.

## Related

- [Editing basics](/docs/sheet/docs/sheet/editing): the editor
- [Ranges, copy and paste](/docs/sheet/docs/sheet/selection): the mouse
- [Translations and messages](/docs/sheet/docs/sheet/more/translations): the shortcut list's texts
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
