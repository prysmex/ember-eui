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

## How they show, how they clear

- **`@validate`'s errors** replace the previous run's when a run ends:
  they clear when a run no longer returns them. A run started while an
  older one waits aborts the older one's `signal` (pass it to `fetch`),
  and an older run's late answer is dropped. An error for a record that
  changed while its run was waiting is dropped too.
- **`@cellErrors`** are yours: shown after the sheet's own messages, as
  long as you pass them. The sheet never clears them; clear a cell's
  error when the cell is written again (the second example), or after
  your next save.
- **A rejected text** (a text the type cannot read) is shown on its
  cell until the cell is written again, and is never sent to you as a
  value ([Errors](/docs/sheet/docs/sheet/validation/field-rules#errors)).

## Related

- [Whole-record checks](/docs/sheet/docs/sheet/validation/record-checks): `@validate` without a server
- [Errors](/docs/sheet/docs/sheet/validation/field-rules#errors): the kinds of errors and their order
- [Your own store](/docs/sheet/docs/sheet/own-store): saving change sets
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
