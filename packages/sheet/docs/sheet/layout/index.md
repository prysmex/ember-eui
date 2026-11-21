---
title: Layout and full screen
order: 9
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: layout and full screen"/>
<EuiSpacer @size="l" />

<EuiText>

Which fields show, their order and widths, fit to content, the row
height, frozen fields and full screen.

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

**Fit to content.** "Fit to content" in a column's header menu, a
double-click on its resize edge, or `api.fitField(fieldId)` give the
column the width of its header label (with the sort arrow and the menu
button) and of its widest cell, between 80 and 480 px; `api.fitFields()`
fits every visible field. The width goes out as a resize's does
(`@onFieldWidthChange`, or the sheet keeps it). A cell is measured as its
formatted text, in the cell's font, at the moment of the fit; a type
whose cell is not text gives `contentWidth(value, field, measure, context)` (the
built-in checkbox, rating, selects, users, linked records and
attachments do). Only the loaded records are measured, the first 2,000
of them: a value on another page does not count. The menu item joins a
header menu that is there anyway: a first field without sort, filter or
field handlers still has no menu (fit it with the double-click or the
API).

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
renders: [Large data](/docs/sheet/docs/sheet/large-data#performance-with-frozen-fields).

## Full screen

The sheet draws no button: put one in `<:toolbar>` and call the block's
`setFullScreen`. The sheet's wrapper (toolbar, grid and footer) then
fills the window, the grid takes the room between the toolbar and the
footer (`@height` is ignored meanwhile) and the page behind does not
scroll. It does what the grid's own full screen does: it sits just
below EUI's header level, so flyouts, modals and toasts stay above it,
and a fixed `EuiHeader` goes below it meanwhile; the sheet's menus,
editors, the expanded record and the shortcut list open above it as
usual. A fixed header of your own (not
`EuiHeader`) with a z-index of 998 or more covers it. The
focused cell, the selection and the scroll stay.

```gjs
<EuiSheet @fields={{this.fields}} @records={{this.records}} …>
  <:toolbar as |sheet|>
    <EuiButtonEmpty
      @size="s"
      @iconType={{if sheet.isFullScreen "fullScreenExit" "fullScreen"}}
      {{on "click" (fn sheet.setFullScreen (if sheet.isFullScreen false true))}}
    >
      {{if sheet.isFullScreen "Exit full screen" "Full screen"}}
    </EuiButtonEmpty>
  </:toolbar>
</EuiSheet>
```

`messages.enterFullScreen` and `messages.exitFullScreen` are those two
labels, translated with the other messages. Escape on a cell ends full
screen when nothing else uses it: an open editor, a menu, the field
editor or the shortcut list closes first, then a lifted column drops
back, the copy mark clears and a range collapses to its cell. Tab works
as without full screen and can leave the sheet for the page behind; put
your own focus trap around the sheet if you need one.
`@fullScreen` and `@onFullScreenChange` control it like the other
presentation state; `api.setFullScreen(on)` sets it from outside.

</EuiText>

<EuiSpacer @size="xl" />

<EuiText>

## Examples

</EuiText>

[[demos-all]]
