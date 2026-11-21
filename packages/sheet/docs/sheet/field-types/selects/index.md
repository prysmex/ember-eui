---
title: Select, multi-select, colours
order: 34
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: select, multi-select and colours"/>
<EuiSpacer @size="l" />

<EuiText>

`singleSelect` stores one option's `value`, `multiSelect` an array of
them. An option has a `value`, a `label` and a `color` (any colour
`EuiBadge` takes); a pasted text that matches no option is rejected, or
becomes a new option with `createOnPaste`.

- **Multi-select**: chips (three, then "+N"). Its editor is a list with
  a search field: a click or Enter toggles an option and the editor stays
  open; Tab or a click elsewhere saves, Escape cancels.

## Related

- [All field types](/docs/sheet/docs/sheet/field-types)
- [Paste rules and new records](/docs/sheet/docs/sheet/selection/paste): `createOnPaste`
- [Row and cell colours](/docs/sheet/docs/sheet/rows/colours): `colorByOption`
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
