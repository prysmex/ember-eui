---
title: Date picker range
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Date picker range"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiDatePickerRange` joins a start and an end date input into one field
with an arrow between them. It only does the layout, so it works with any
date input: `EuiPikaday` or `EuiFlatpickr` from their addons, or a native
`<EuiFieldText type="date">`.

```hbs
<EuiDatePickerRange>
  <:start as |className|>
    <EuiFieldText @controlOnly={{true}} type="date" class={{className}} aria-label="Start date" />
  </:start>
  <:end as |className|>
    <EuiFieldText @controlOnly={{true}} type="date" class={{className}} aria-label="End date" />
  </:end>
</EuiDatePickerRange>
```

Render each input without its own frame (`@controlOnly={{true}}`) and give
it the class its block yields, which removes its border and rounds only
the outer corners. Check that the end is not before the start and mark
both inputs `@isInvalid` if it is.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiDatePickerRange

Two date inputs joined in one field with an arrow between them, for a
start and end date. It only does the layout: put any date input in the
blocks (`EuiPikaday`, `EuiFlatpickr`, or `<EuiFieldText type="date">`),
rendered without their own frame (`@controlOnly={{true}}`) and with the
class each block yields.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@fullWidth` | `boolean` |  | Takes the container's full width instead of 400px at most. |
| `@readOnly` | `boolean` |  | Read-only look. |

| Block | Description |
| --- | --- |
| `<:start>` | The start input; yields the classes to give it. |
| `<:end>` | The end input; yields the classes to give it. |
| default block | Anything else, instead of the start and end blocks. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
