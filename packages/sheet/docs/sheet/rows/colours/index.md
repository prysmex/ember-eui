---
title: Row and cell colours
order: 72
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: row and cell colours"/>
<EuiSpacer @size="l" />

<EuiText>

A colour bar per row (`@rowColor`) and per cell (`@cellColor`), from
your own rules, in the theme's colours.

## Row and cell colours

**Row colours.** `@rowColor={{this.colorOf}}` returns a colour per
record, drawn as a 4 px bar at the row's left edge: on the row-number
cell (sticky with it when fields are frozen), or on the first field's
cell without row numbers. `'primary'`, `'accent'`, `'success'`,
`'warning'`, `'danger'` and `'neutral'` are the theme's
(`--euiSheet-row<Name>`), so dark mode follows; any other value is a CSS
colour used as given (yours to fit dark mode); `undefined` draws none.
`colorByOption(field)` returns the record's option's `color` of a select
field (the badge's colour; `'default'` is `'neutral'`). The colour has
no text: a screen reader does not hear it, so put its meaning in a field
too. `@rowColor` is called for each rendered row: keep it cheap.

**Cell colours.** `@cellColor={{this.cellColor}}` returns a colour per
cell, from the record and the field, drawn as a 3 px bar along the
cell's bottom edge. It takes the same colours as `@rowColor` (the named
ones are the same tokens, so dark mode follows; any other value is a CSS
colour as given) and `undefined` draws none. The rule is yours; the
sheet only draws it:

```js
cellColor = (task, field) =>
  field.id === 'due' && !task.done && task.due && task.due < today ? 'danger' : undefined;
```

The bar shows with everything else a cell can have: the error border, the
row's bar on the first field, the search match ring, an upload's progress
(the bar sits just above it), a frozen cell, the selection and the focus
ring (it sits inside them). Group headers and the add row have none. The
cell's label does not change: a screen reader does not hear the colour,
so put its meaning in a field or in `@cellErrors` too.

`@cellColor` is called for each rendered cell of a record, each time the
cell renders (scrolling, the selection moving, a new `@records`): keep
it cheap, with no lookups across rows. Read only the record and the
field it is given; precompute anything that needs the other records (a
duplicate check, a total) once when `@records` changes, and read the
result by id.

## Related

- [Blocking and warnings](/docs/sheet/docs/sheet/validation/blocking-and-warnings): a colour as a warning
- [Theming and dark mode](/docs/sheet/docs/sheet/more/theme)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
