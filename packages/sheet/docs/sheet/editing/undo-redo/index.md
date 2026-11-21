---
title: Undo and redo
order: 22
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: undo and redo"/>
<EuiSpacer @size="l" />

<EuiText>

Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z, and `api.undo()` and `api.redo()` from
your own buttons. An undo is one more change set: you apply it like any
other.

## Undo and redo

Ctrl/Cmd+Z undoes the last change made in the sheet (an edit, a paste, a
clear, a fill, a checkbox toggle, an insert, a duplicate, a delete or a
move of records); Ctrl/Cmd+Shift+Z and Ctrl+Y redo it.
The sheet keeps the last 100 change sets it emitted, per sheet, and an
undo is one more change set through `@onChange`: `source: 'undo'`, each
patch with `from` and `to` swapped, and the rows a paste inserted listed
in `deletes` (a redo emits the original again, `source: 'redo'`, with the
same `tempId`s). `applyChangeSet` and `localRecords` apply `deletes`; with
your own store, remove those records.

- An undo or redo only writes cells that still hold the value the change
  left there. A cell you changed since (from your store, a server or
  another user) is skipped; if nothing is left, nothing is emitted.
- An inserted row is found by its `tempId`. If your store gives the new
  record another id, call `api.remapIds({ [tempId]: newId })`, before or
  with the `@records` that carry the new id, and undo finds it again;
  without it, the row is not removed by undo (it is skipped). A row
  changed since it was inserted is not removed either.
- An undo of a delete puts each record back after the neighbour it had,
  even when your records were re-sorted since. An undo of a move moves
  each record back after the record that was before it (or first), in
  the same order, with the group values it had. A redo of a delete names
  the record's id; if your server gave the restored record a new id,
  call `remapIds` for it too.
- A change whose records are not in `@records` any more (another page, a
  filter) is skipped, and stays on the stack: Ctrl/Cmd+Z does nothing
  until those records are back (the page where you made it), then undoes
  it. Call `api.clearHistory()` when your data changes wholesale (or on a
  page change, if you prefer that).
- Rejected texts are part of the change that made them: undoing a paste
  also removes the texts it could not read (the cells show their values
  again, without the red border), and a redo shows them again on the
  cells that still hold the value they had. A paste where every cell was
  rejected is undone too. The owner gets no change set for that part
  (nothing in the data changes).
- Options created on paste (`createOnPaste`) stay after an undo.
- Changes to `@records` made outside the sheet are not undone, a new
  change clears the redo history, and with `@readOnly` undo and redo do
  nothing. In an open editor, Ctrl/Cmd+Z is the input's own undo.

## Related

- [Your own store](/docs/sheet/docs/sheet/own-store): `remapIds` for the ids your server gives
- [Editing basics](/docs/sheet/docs/sheet/editing)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
