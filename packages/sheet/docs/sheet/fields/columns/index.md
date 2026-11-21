---
title: Hide, reorder, resize, freeze
order: 52
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: hide, reorder, resize and freeze"/>
<EuiSpacer @size="l" />

<EuiText>

Which fields show, their order and widths, long header labels and
frozen fields: the presentation state, which the sheet keeps itself or
leaves to you.

## Presentation state

Which fields show, their order, their widths and the row height work the
same way: **with a handler, the sheet shows exactly the argument** and only
calls the handler, so if you pass the handler and do not update the
argument, nothing changes on screen (in development the sheet warns once).
**Without a handler, the sheet keeps its own state**, so a sheet with only
`@fields` still lets people hide, move and resize columns: "Hide column"
really hides (the field goes to the hidden list and the expanded record),
and copy and paste skip hidden fields. The first field cannot be hidden or
moved, and nothing can move before it.

Drag a header to move its field (`@fieldDrag`, on by default): the drop
calls `@onFieldOrderChange` with the new order, as "Move left/right" does,
or moves the column itself without the handler. A drop before the first
field puts the field second. With the keyboard, focus a header, press
Space, move it with the arrows and press Space to drop it (Escape
cancels); Enter still opens the header menu. A click on a title still
selects the column. Drags start from a mouse or a pen, not a touch: on a
phone use the menu's "Move left/right". The row-number column cannot be
dragged. `@fieldDrag={{false}}` gives the header the DOM of v0.2 (no drag
wrappers; the column resizer inside the header cell).

`@headerLines={{2}}` (or `3`) lets long header labels wrap instead of
being cut, independently of `@rowHeight`: the header row grows and the
rows start below it.

## Frozen field

With `@frozenFields={{1}}` the first field stays in view when the grid
scrolls sideways, and so do the row numbers, its header and its summary
cell. `@frozenFields={{2}}` freezes two fields. It is off by default.
A frozen field always has a
width (200 px unless `@fieldWidths` or `field.width` say otherwise), and
resizing it moves the frozen edge. Keyboard focus that would land under
the frozen columns scrolls the cell clear, and focusing a frozen cell
(a click, ArrowLeft into it) does not scroll the grid.

What a frozen field costs while scrolling, and how many cells it
renders: [Large data](/docs/sheet/docs/sheet/data/large-sheet#performance-with-frozen-fields).

## Related

- [Full screen and fit width](/docs/sheet/docs/sheet/more/full-screen)
- [Large data](/docs/sheet/docs/sheet/data/large-sheet): what freezing costs
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
