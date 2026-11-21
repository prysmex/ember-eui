---
title: Selection, copy and paste
order: 4
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: selection, copy and paste"/>
<EuiSpacer @size="l" />

<EuiText>

Ranges with the mouse and the keys, the fill handle, how a paste
lands, summaries of the data and of the selection, and touch.

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

## The fill handle

The fill handle is the small square at the bottom-right corner of the
selected range. Drag it down, up, right or left: the cells it covers
are outlined, and the release fills them from the range. Numbers
(number, currency, percent, duration, rating) with a constant step
continue it (`1, 2` gives `3, 4`); one date continues by a day, and two
or more dates with a constant step continue it (weekly stays weekly);
anything else repeats in order. Hold Ctrl or Alt (Option) when you
release to repeat instead. Escape during the drag cancels it. Values are
copied as they are (an array too: do not change it in place); across
fields of different types they go through text, like a paste. A fill is
one undo step. The handle is for a mouse; Ctrl/Cmd+D and Ctrl/Cmd+R
are the keyboard's fills. A custom type continues its own values with
`series(samples, count, field, direction)`.

## Paste

A paste starts at the top left cell of the selection. Columns past the
last field are dropped, read-only cells are skipped, and rows past the
end become inserts. When the selection is larger than the copied block
and its height and width are whole multiples of the block's, the block
is repeated over the whole selection, as in Excel: one copied cell
fills every selected cell. Otherwise the block is pasted once.

## Summary bar

Pass `@summary` (even `{}`) to show a footer row under the grid: each
field's text under it, and `@summary['']` under the row numbers (a count,
say). The cells are plain text: no editing, no selection. The sheet
computes nothing, because with paged data a summary of the loaded page
would be wrong: take the values from your backend (its aggregations), or,
when you have every record, compute them with `summarize`:

```js
import { builtInFieldTypes, defaultMessages, summarize } from '@ember-eui/sheet';

summarize({ types: builtInFieldTypes, messages: defaultMessages }, records, field, 'sum');
```

The kinds are `count`, `filled`, `empty`, `percentFilled`, `unique`,
`sum`, `average`, `min`, `max`, `checked` and `unchecked`. Sums and
averages use the type's `toNumber` (numbers have it), minimum and maximum
`toNumber` or else `compare` (dates, text), and the text is formatted with
the type's `format`. What to summarize is your control, in `<:toolbar>`
or `<:footer>`.

**A summary of the selection.** The blocks' `selection`,
`api.getSelection()` and `@onSelectionChange` give the selected cells:
`{ kind: 'cells' or 'rows' or 'columns', records, recordIds, fields,
cellCount }`, records in the order shown and the visible fields in
display order. A focused cell is a selection of one cell; group headers
and add rows inside a range are not in it, and the checked rows stay
separate (`checkedRecords`). `@onSelectionChange` is called after the
render, at most once per run loop, when the record ids, the field ids or
the kind changed (`null` when there is none), so a drag reports each new
rectangle once: keep it cheap, or debounce it. The sheet aggregates
nothing: call `summarize` per field, or `summarizeCells` for one figure
over every cell, as Airtable's bar does:

```js
import { summarizeCells } from '@ember-eui/sheet';

summarizeCells(ctx, selection, 'sum'); // 'count', 'filled', 'sum', 'average', 'min', 'max'
```

Numbers go through each type's `toNumber`; with one field the result
has its `format` (a currency, a percent), with several it is a plain
number with at most two decimals; `''` when no cell has a number. A
selection holds loaded records only, so its summary is exact; a summary
of "all" is yours (`@summary`).

## Touch

On a phone or a tablet, a tap selects a cell and a tap on the selected
cell edits it. A drag scrolls. After a tap the selected cell has two
round handles, at its top-left and bottom-right corners (as in Google
Sheets): drag the bottom-right one to extend the range, the top-left one
to move its other corner; near the grid's edges the drag scrolls. A
handle hides while its corner is scrolled out of view or under the
frozen fields, and the handles never show after a mouse press (a hybrid
device). Row numbers, column titles and Ctrl/Cmd+A still select too. A
long press on a range opens the menu with Copy and Paste (the
clipboard's text over the range; the browser may ask for permission).
A long
press on a cell or a row number opens the row menu (Android Chrome fires
its own context menu event; on iOS Safari the sheet's 500 ms timer opens
it; a press that moves more than 10 px is a scroll). The ▾ and calendar
buttons, the row checkbox and the expand icon are always shown on touch
screens, with larger touch areas. With `@editIn` at its default, a sheet
narrower than 600 px on a touch screen edits in the expanded record,
with the tapped field's editor open. The fill handle is not shown on
touch screens (the selection handles take its place). None of this was
tried on a real phone yet: the handles were checked with synthetic touch
events and Chromium's touch emulation only.

</EuiText>
