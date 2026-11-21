---
title: Large data
order: 83
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: large data"/>
<EuiSpacer @size="l" />

<EuiText>

One sheet of 10,000 records and 30 fields, alone on its page. The docs
render every example of a page at once, and a render pass (one per
scroll step) revalidates everything on the page, so a large sheet among
other examples measures and feels slower than it is in an app that
shows it alone.

## Performance with frozen fields

The grid can only keep a cell pinned while it stays mounted, so while a
field is frozen it always renders the frozen columns (and the row
numbers) besides the columns in view; the other columns are virtualized
as without freezing, and so are the rows. So the number of records and
of fields hardly matters:

| | Cells rendered |
| --- | --- |
| Not frozen | rows in view × columns in view |
| Frozen | rows in view × (frozen columns + columns in view) |

At the left edge the frozen columns are among the columns in view anyway:
in the sheet's own test (FZ9: 10,000 records × 30 fields, 12 rows
rendered, headless Chromium, 20 scroll steps of 600 px) both render 72
cells, and a scroll step takes the same time frozen or not (104 and
106 ms in one run on a loaded machine; take the absolute numbers as a test
machine's). Scrolled sideways, a row renders the frozen cells more. (Up
to this release the frozen grid rendered every column of the rendered
rows: 372 cells there, about four times the time per step.)

What a scroll step costs grows with the cells in view: a wide or tall
grid (`@height`), and heavy cells (attachment thumbnails, linked-record
chips, your own cell components from `@fieldTypes`). Above 50 visible
fields the sheet does not freeze at all, and `@frozenFields` is ignored.

</EuiText>
