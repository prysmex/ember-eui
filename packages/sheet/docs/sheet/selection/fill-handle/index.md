---
title: Fill handle
order: 62
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: fill handle"/>
<EuiSpacer @size="l" />

<EuiText>

The square at a range's corner: drag it to repeat the range or continue
its series. Ctrl/Cmd+D and Ctrl/Cmd+R fill from the keyboard.

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

## Related

- [Ranges, copy and paste](/docs/sheet/docs/sheet/selection)
- [Custom field types and editors](/docs/sheet/docs/sheet/field-types/custom-types): a type's own `series`
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
