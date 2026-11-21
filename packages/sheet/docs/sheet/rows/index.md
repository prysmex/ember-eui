---
title: Records and rows
order: 7
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: records and rows"/>
<EuiSpacer @size="l" />

<EuiText>

The row numbers, checkboxes, the add row, the row menu and row drag;
the expanded record and its footer; row and cell colours.

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
  run past the last record get only the pasted values.
- **The row menu**: right-click a cell or a row number, or press
  Shift+F10 or the ContextMenu key. It has Insert record above and below,
  Duplicate, Expand record (for one record), Copy (the rows as
  tab-separated text), with `@copyWithFieldNames` "Copy with field names"
  (the same rows after a line of the visible fields' labels, or ids, for
  a report or an email), your `@rowActions` and Delete. Escape or a click
  outside closes it. A paste of that text back into the sheet pastes the
  names as a row, like any text. There is no delete key for rows: Delete and
  Backspace clear cells.

- **Moving** (with `@canMove`): each row number has a grip (shown on
  hover and focus, always on a touch screen; the column is 12 px wider).
  Drag it: a line shows where the rows go, the grid scrolls near its
  edges, Escape cancels, and the release emits one change set. The
  pressed row moves, or all the checked rows when it is checked, or the
  rows of a selection of whole rows; they keep their order and are
  selected after the move. Alt+Shift+ArrowUp / ArrowDown on a row number
  (or with whole rows selected) moves them one record. A drop that
  changes nothing emits nothing. With a `@sort` there is no grip: the
  order is the sort's. With groups, a drop on a header goes to the start
  of its group (a collapsed one: into it, with no anchor), on a group's
  add row to its end, and a drop in another group also writes that
  group's values; it is not allowed (a red line) when one of those
  fields is read-only for a moved record. A drag stays on the page the
  sheet has. Not by touch in v0.3 (a touch drag scrolls): on a phone use
  the keys or `api.moveRecords`.

Each of these is a change set (`insert`: `inserts` with `index` and
`anchor`; `delete`: `deletes` and `removed`; `move`: `moves`) and one
undo step: an undone delete puts the same records back where they were,
an undone move puts them back in their old place.

All of this works on the rows the sheet has: with a paging owner, the
checkboxes and the selection are those of the page shown.

## Expanded record

Space on a cell, Enter on a row number, the expand icon, the menu, or
`api.expandRecord(id)` open a record: in a flyout by default, or in a
modal with `@expandedRecord="modal"`. It lists the fields of `@fields`
and then those of `@hiddenFields`, each a label and a box with the same
cell the grid shows, and its errors under it. Its title is the first
field's text; the arrows go to the previous and next record.

- A box opens the field's editor in place: a click, Enter, F2 or typing
  (as on a cell). Space and a checkbox's click toggle it; Delete clears
  it. One editor is open at a time.
- In the editor, Enter saves and goes to the next field, Tab and
  Shift+Tab save and move on, Escape cancels (it does not close the
  record). Ctrl/Cmd+Z undoes, as in the grid.
- Every save is a change set like an edit in the grid: validated, with
  rejected texts shown in the box and in the cell.
- Escape on a box, the close button, or the record leaving `@records`
  close it; focus goes back to the cell it was opened from.
- While an editor is open, the flyout's or modal's focus trap is off, so
  an editor that renders part of itself elsewhere on the page (a
  calendar) works there too.

`<:recordFooter as |record sheet|>` adds your own block below the fields
(and the hidden fields), after a line, in the flyout and in the modal:
`record` is the expanded record, `sheet` the block API the toolbar gets.
The arrows re-render it with the next record. It is inside the shell's
focus trap, so its inputs and buttons work with the keyboard; the
record's keys stay on its boxes, so typing in the block types there, and
Escape in a text box of the block does not close the record.

```gjs
<EuiSheet @fields={{this.fields}} @records={{this.records}} …>
  <:recordFooter as |record|>
    <MyComments @recordId={{record.id}} />
  </:recordFooter>
</EuiSheet>
```

The sheet stores no comments or history: they are your data, shown by
your component.

## Row and cell colours

**Row colours.** `@rowColor={{this.colorOf}}` returns a colour per
record, drawn as a 4 px bar at the row's left edge: on the row-number
cell (sticky with it when fields are frozen), or on the first field's
cell without row numbers. `'primary'`, `'accent'`, `'success'`,
`'warning'`, `'danger'` and `'neutral'` are the theme's
(`--euiSheet-row<Name>`), so dark mode follows; any other value is a CSS
colour used as given (yours to fit dark mode); `undefined` draws none.
`colorByOption(field)` returns the record's option's `color` of a select
field (the badge's colour; `'default'` is `'neutral'`). The colour has
no text: a screen reader does not hear it, so put its meaning in a field
too. `@rowColor` is called for each rendered row: keep it cheap.

**Cell colours.** `@cellColor={{this.cellColor}}` returns a colour per
cell, from the record and the field, drawn as a 3 px bar along the
cell's bottom edge. It takes the same colours as `@rowColor` (the named
ones are the same tokens, so dark mode follows; any other value is a CSS
colour as given) and `undefined` draws none. The rule is yours; the
sheet only draws it:

```js
cellColor = (task, field) =>
  field.id === 'due' && !task.done && task.due && task.due < today ? 'danger' : undefined;
```

The bar shows with everything else a cell can have: the error border, the
row's bar on the first field, the search match ring, an upload's progress
(the bar sits just above it), a frozen cell, the selection and the focus
ring (it sits inside them). Group headers and the add row have none. The
cell's label does not change: a screen reader does not hear the colour,
so put its meaning in a field or in `@cellErrors` too.

`@cellColor` is called for each rendered cell of a record, each time the
cell renders (scrolling, the selection moving, a new `@records`): keep
it cheap, with no lookups across rows. Read only the record and the
field it is given; precompute anything that needs the other records (a
duplicate check, a total) once when `@records` changes, and read the
result by id.

</EuiText>
