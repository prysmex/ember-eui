---
title: Ranges, copy and paste
order: 60
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: ranges, copy and paste"/>
<EuiSpacer @size="l" />

<EuiText>

Selecting cells, rows and columns with the mouse and the keys, and
copying and pasting them to and from Excel or Google Sheets as
tab-separated text.

## The mouse and ranges

With the mouse, as in Airtable: a click selects a cell (a blue ring), a
click on the selected cell edits it, and a double-click edits at once.
Pressing on a cell and dragging over others selects that range (the
release does not edit or toggle); Shift+arrows then continue from it.

The active cell stays where a range started, as in Airtable and
spreadsheets: a drag, Shift+click, Shift+arrows and the Shift+Ctrl/Cmd
jumps move only the range's far corner, which is scrolled into view, and
the ring stays on the first cell. Typing or Enter edits that cell; a
plain arrow or click moves it and collapses the range; Delete, copy, cut,
paste and fill use the whole range. A range of more than one cell has a
3 px outline, and the active cell inside it keeps a plain background. The
headers of the range's columns and the numbers of its rows are marked in
the primary colour; a selected column's header and a selected row's
number also get a 3 px bar. Checked rows have a light tint.

After a copy or a cut the copied cells keep a dashed outline until
Escape, a change or the next copy. The cells a paste, fill, undo or redo
changed flash briefly (not with reduced motion). While the fill handle is
dragged, its target area has a dashed outline. A right-click (or a long
press) on a cell or a row number opens the row menu, on a header the
header menu; Shift+F10 opens the row menu from the keyboard.

## Related

- [Paste rules and new records](/docs/sheet/docs/sheet/selection/paste)
- [Fill handle](/docs/sheet/docs/sheet/selection/fill-handle)
- [Summary footer](/docs/sheet/docs/sheet/selection/summary)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
