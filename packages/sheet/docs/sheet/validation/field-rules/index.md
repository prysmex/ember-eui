---
title: Field rules
order: 10
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: field rules"/>
<EuiSpacer @size="l" />

<EuiText>

The rules a field carries itself: `required`, a number's `min` and
`max`, a text's `maxLength` and `pattern`, a date's range, the formats
of email, URL and phone fields, and `field.validate(value, record)` for
anything else about one value. The sheet checks them on every stored
value, shows the message on the cell and never blocks the change. What
a type cannot read at all (`abc` in a number) is not stored: it is a
rejected text.

## Errors

A cell with an error has a red border. When it has focus, its messages
show in a box under it (and are announced to screen readers); hovering
it shows them too.
There are three kinds:

- **Rejected text**: a text the type cannot read, such as `abc` in a
  number field, typed or pasted. It makes no patch: the record keeps
  its value, the change set lists it in `rejected`, and the cell shows
  the text, marked invalid, until the cell is written again (or you
  change the value: the sheet compares with the value it saw). On a
  new record (a paste on the add row or past the end, `appendRows`) it
  compares with the value the record arrives with in `@records`, so a
  default from your `createRecord` (`qty: null`) keeps it shown.
- **Validation errors**: a stored value that breaks a rule: `required`,
  the type's options (`min`, `max`, `maxLength`, `pattern`, an unknown
  option, a bad date), `field.validate(value, record)`, and `@validate`
  for rules that need the whole record, other rows or a server. They
  never block a change.
- **`@cellErrors`**: your own errors, for example from saving to your
  API. Shown last.

A cell shows its messages in that order. A rejected cell shows only its
rejection and `@cellErrors`: the other rules would describe the old
value.

## Related

- [Whole-record checks](/docs/sheet/docs/sheet/validation/record-checks): rules over several fields or rows
- [Server checks and rejections](/docs/sheet/docs/sheet/validation/server-checks)
- [Blocking and warnings](/docs/sheet/docs/sheet/validation/blocking-and-warnings)
- [All field types](/docs/sheet/docs/sheet/field-types): every type's options
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
