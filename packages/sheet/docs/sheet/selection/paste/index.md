---
title: Paste rules and new records
order: 61
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: paste rules and new records"/>
<EuiSpacer @size="l" />

<EuiText>

Where a paste lands, how it repeats over a larger selection, what
happens to texts that match no option, and the records it adds past the
end.

## Paste

A paste starts at the top left cell of the selection. Columns past the
last field are dropped, read-only cells are skipped, and rows past the
end become inserts. When the selection is larger than the copied block
and its height and width are whole multiples of the block's, the block
is repeated over the whole selection, as in Excel: one copied cell
fills every selected cell. Otherwise the block is pasted once.

## Related

- [Ranges, copy and paste](/docs/sheet/docs/sheet/selection)
- [Validation while pasting and importing](/docs/sheet/docs/sheet/validation/paste-and-import)
- [Add, delete, duplicate](/docs/sheet/docs/sheet/rows): `@newRecordValues`
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
