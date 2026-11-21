---
title: Row drag and order
order: 71
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: row drag and order"/>
<EuiSpacer @size="l" />

<EuiText>

With `@canMove`, rows move by dragging their grip or with
Alt+Shift+ArrowUp/Down. The sheet moves nothing: it sends the moves, you
put the records in their new order.

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

## Moves in the change set

With `@canMove`, a row drag ([Records](/docs/sheet/docs/sheet/rows#records)) emits `source: 'move'` and
`moves`: one `{ recordId, anchor?, groupKey?, from }` per moved record,
in their final order. Apply them in order: take the record out and put
it back before or after `anchor.recordId` (the first move is anchored to
a record that does not move, each next one after the previous). A move
without an anchor goes into `groupKey`, a group with no loaded record to
anchor to; its patches already wrote the group's values. `from` (the
record before it and its group) is what undo uses. `applyChangeSet` and
`localRecords` apply moves; an owner that ignores them shows nothing
moving, which is why row drag is opt-in. Keep the order in your data: an
order column, or fractional positions (a move then writes one record).

## Related

- [Add, delete, duplicate](/docs/sheet/docs/sheet/rows)
- [Sorting](/docs/sheet/docs/sheet/data/sorting): no drag while sorted
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
