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

## Related

- [Field rules](/docs/sheet/docs/sheet/validation/field-rules)
- [Server checks and rejections](/docs/sheet/docs/sheet/validation/server-checks): `@validate` with a server
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
