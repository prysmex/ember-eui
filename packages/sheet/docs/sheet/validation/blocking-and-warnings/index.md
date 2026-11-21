---
title: Blocking and warnings
order: 13
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: blocking and warnings"/>
<EuiSpacer @size="l" />

<EuiText>

The sheet has one kind of validation message, and it blocks only one
thing: a text the field's type cannot read is not stored. Every other
error is shown on a value that is stored. There is no warning level;
this page shows what to use instead, and how your app can refuse to
submit records with errors.

## What blocks, and what does not

- **A text the type cannot read** (`abc` in a number, a date that does
  not exist, a select text that is no option): the sheet stores nothing.
  The change set lists it in `rejected`, and the cell shows the text,
  marked, until the cell is written again. This is the only thing the
  sheet refuses.
- **A value that breaks a rule** (`required`, `min`, `max`, `pattern`,
  `field.validate`, `@validate`): stored, and marked. What to do with a
  record that has errors is your app's choice: keep a Submit button off
  while there are any, say. `validateCell(ctx, field, record)` runs a
  field's rules as the sheet does (of its `ctx` only `types` and
  `messages` are read: `{ types: builtInFieldTypes, messages:
defaultMessages }`, as `summarize` takes); the rules of your `@validate` are your own
  code already.
- **What your server refused** (`@cellErrors`): shown after the rest,
  until you take it away ([Server checks and
  rejections](/docs/sheet/docs/sheet/validation/server-checks)).

## Warnings

A message on a cell is an error: there is no lighter level (no
"warning" messages, no severity). For a softer signal, draw it with
`@cellColor` (a `'warning'` bar, [Row and cell
colours](/docs/sheet/docs/sheet/rows/colours)) and put its meaning where
it is read out (a list, a field, your own tooltip), since a colour has
no text. A warning that must stop someone is an error.

## Related

- [Errors](/docs/sheet/docs/sheet/validation/field-rules#errors): the kinds of errors
- [Row and cell colours](/docs/sheet/docs/sheet/rows/colours)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
