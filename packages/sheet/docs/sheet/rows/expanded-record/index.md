---
title: Expanded record
order: 74
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: expanded record"/>
<EuiSpacer @size="l" />

<EuiText>

One record as a form, in a flyout or a modal: every field, the hidden
ones too, with its cell, editor and errors.

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

## Related

- [Record footer](/docs/sheet/docs/sheet/rows/record-footer)
- [Touch selection](/docs/sheet/docs/sheet/selection/touch): editing in the record on a phone
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
