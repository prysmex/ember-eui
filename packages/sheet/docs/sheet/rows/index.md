---
title: Add, delete, duplicate
order: 70
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: add, delete and duplicate"/>
<EuiSpacer @size="l" />

<EuiText>

The row numbers and checkboxes, the add row, Shift+Enter and the row
menu: inserting, duplicating and deleting records, each one change set
and one undo step.

## Records

A row-number column comes first. It shows each row's position (with
`@rowNumberOffset` added, so page 2 goes on from page 1), or what
`@rowLabel` returns. The number is the position, not the record's id:
pass `@rowLabel={{(record) => record.id}}`, or add the id as a field, to
show ids. Hovering a row shows its checkbox and an expand icon.

- **Selecting rows**: a click on a row number selects the whole row,
  Shift+click or a drag over the numbers selects more. A click on a
  column's title selects its cells (Shift+click: more columns); the
  column's actions button keeps its own menu. Delete, copy and paste use
  that selection like any other.
- **Checkboxes**: a click toggles a row, Shift+click every row from the
  last one toggled, and the header's checkbox all rows or none. Checked
  rows are what the row menu and your `@rowActions` act on; with none
  checked, the selected rows.
- **Adding**: the last row of the grid is an "Add record" row: a click,
  or Enter on it, adds a record at the end and focuses its first editable
  cell. Shift+Enter on a cell adds one below it. A paste on the add row
  adds its lines as records; the fields the pasted text has no column for
  get `@newRecordValues` (once per line, the record above the add row as
  `above`), as `api.appendRows` does. Lines of a paste from a record that
  run past the last record are new records too, and get
  `@newRecordValues` the same way (once per new record, the last record
  as `above`); the records pasted over get only the pasted values.
- **The row menu**: right-click a cell or a row number, or press
  Shift+F10 or the ContextMenu key. It has Insert record above and below,
  Duplicate, Expand record (for one record), Copy (the rows as
  tab-separated text), with `@copyWithFieldNames` "Copy with field names"
  (the same rows after a line of the visible fields' labels, or ids, for
  a report or an email), your `@rowActions` and Delete. Escape or a click
  outside closes it. A paste of that text back into the sheet pastes the
  names as a row, like any text. There is no delete key for rows: Delete and
  Backspace clear cells.

Each of these is a change set (`insert`: `inserts` with `index` and
`anchor`; `delete`: `deletes` and `removed`; `move`: `moves`) and one
undo step: an undone delete puts the same records back where they were,
an undone move puts them back in their old place.

All of this works on the rows the sheet has: with a paging owner, the
checkboxes and the selection are those of the page shown.

## Related

- [Row drag and order](/docs/sheet/docs/sheet/rows/drag)
- [Expanded record](/docs/sheet/docs/sheet/rows/expanded-record)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
