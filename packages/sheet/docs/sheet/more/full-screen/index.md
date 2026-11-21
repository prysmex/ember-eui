---
title: Full screen and fit width
order: 100
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: full screen and fit width"/>
<EuiSpacer @size="l" />

<EuiText>

The sheet filling the window from your own toolbar button, and columns
fitted to their content.

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

## Fit to content

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

## Related

- [Hide, reorder, resize, freeze](/docs/sheet/docs/sheet/fields/columns)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
