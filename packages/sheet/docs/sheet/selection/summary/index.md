---
title: Summary footer
order: 64
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: summary footer"/>
<EuiSpacer @size="l" />

<EuiText>

A footer row of totals under the grid (`@summary`), and a summary of the
selected cells: the sheet draws them, you compute them (`summarize`,
`summarizeCells`).

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

## Related

- [Groups](/docs/sheet/docs/sheet/data/record-groups): summaries per group
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
