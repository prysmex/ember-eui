---
title: Buttons
order: 41
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: buttons"/>
<EuiSpacer @size="l" />

<EuiText>

A `button` field stores nothing: each cell is a button that runs your
action on its record (`@onButtonPress`) or opens a link.

- **Button**: a button with the field's text, icon and colour; a click
  on it, or Enter or Space on the selected cell, calls `@onButtonPress`
  with the record (route by `fieldId`), or, without it, opens
  `url(record)` in a new tab. A promise shows a spinner and ignores
  presses until it settles; a rejection's message is the cell's error
  until the next press. `disabled(record)` draws it disabled; with
  neither a handler nor a `url` every button is disabled (and a warning
  says so once). A press is not a change set and is not undoable. It
  copies its text, so a copied range lines up. In the expanded record it
  is a real button.

## Related

- [All field types](/docs/sheet/docs/sheet/field-types)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
