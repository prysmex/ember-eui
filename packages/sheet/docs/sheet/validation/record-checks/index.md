---
title: Whole-record checks
order: 11
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: whole-record checks"/>
<EuiSpacer @size="l" />

<EuiText>

Rules that need more than one value: an end date after its start, a
field required only in some records, a serial number used once. A
field's `required` and `readOnly` can be functions of the record, and
`@validate` sees every record at once.

## Rules that depend on the record

`required` and `readOnly` take a function of the record as well as a
boolean: `required: (permit) => permit.status === 'closed'`. The sheet
calls it for each record it checks or draws, so keep it cheap and read
only that record.

## @validate

`@validate({ records, changed, signal })` returns the errors it finds,
or a promise of them, keyed as `@cellErrors` are: `{ [recordId]: {
[fieldId]: message or messages } }`. The sheet runs it on the first
render, when `@records` changes and after each change set it sends
(debounced); `changed` lists the cells written since the last run
(empty on the first), so a rule can check only those. Each run's
errors replace the last run's: an error goes away when a run no longer
returns it. A rule that needs a server returns a promise: [Server checks
and rejections](/docs/sheet/docs/sheet/validation/server-checks).

## Related

- [Field rules](/docs/sheet/docs/sheet/validation/field-rules)
- [Server checks and rejections](/docs/sheet/docs/sheet/validation/server-checks): `@validate` with a server
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
