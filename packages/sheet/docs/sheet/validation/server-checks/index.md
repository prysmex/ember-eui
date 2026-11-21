---
title: Server checks and rejections
order: 12
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: server checks and rejections"/>
<EuiSpacer @size="l" />

<EuiText>

Rules only your server can answer (is this email blocked, is this serial
number taken) and errors from saving. `@validate` may return a promise:
the sheet aborts a run when a newer one starts and drops a late answer.
What your API refused when you saved goes in `@cellErrors`, shown after
every other message, until you take it away.

## Related

- [Whole-record checks](/docs/sheet/docs/sheet/validation/record-checks): `@validate` without a server
- [Errors](/docs/sheet/docs/sheet/validation/field-rules#errors): the kinds of errors and their order
- [Your own store](/docs/sheet/docs/sheet/own-store): saving change sets
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
