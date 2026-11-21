---
title: Touch selection
order: 63
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: touch selection"/>
<EuiSpacer @size="l" />

<EuiText>

On a phone or a tablet: taps, the selection handles, the long press
menu, and editing in the expanded record on a narrow screen.

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

## Related

- [Ranges, copy and paste](/docs/sheet/docs/sheet/selection)
- [Expanded record](/docs/sheet/docs/sheet/rows/expanded-record)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
