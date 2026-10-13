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
start and end date (upstream `EuiDatePickerRange`, built on
`EuiFormControlLayoutDelimited`). It only does the layout: put any date
input in the blocks (`EuiPikaday`, `EuiFlatpickr`, or
`<EuiFieldText type="date">`), rendered without their own frame
(`@controlOnly={{true}}`) and with the class each block yields.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@fullWidth` | `boolean` |  | Takes the container's full width instead of 400px at most. |
| `@readOnly` | `boolean` |  | Read-only look. |
| `@compressed` | `boolean` |  | Shorter control (32px instead of 40px). |
| `@disabled` | `boolean` |  | Disabled look. Disable the inputs themselves too. |
| `@isInvalid` | `boolean` |  | Invalid look: danger outline, danger delimiter and a warning icon. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@iconType` | `boolean \| string` |  | Icon at the start: `true` (the default) shows `calendar`, `false` hides it, or any `EuiIcon` type. |
| `@iconSide` | `'left' \| 'right'` |  | Side of `@iconType`: `'left'` (default) or `'right'`. Applies only to an icon type, not to the default `calendar` (`@iconType={{true}}`). |
| `@isCustom` | `boolean` |  | Custom controls: the `<:start>` / `<:end>` blocks yield only the delimited input class, without the date picker range classes (upstream doesn't add its props to the controls). |
| `@delimiter` | `string` | an arrow icon labelled "to" | Text between the inputs. |
| `@inline` | `boolean` |  | For two calendars displayed in the page (e.g. inline flatpickr or pikaday calendars in the blocks): drops the field frame, the icon and `@fullWidth`/`@compressed`, lays the blocks out side by side and stacks them when the container is too narrow. Pass the inline option to your calendars too. |
| `@showTimeSelect` | `boolean` |  | With `@inline`: tells the range that the calendars show a time list (react-datepicker's `showTimeSelect`), so they stack below a wider container (2 × 374px + the delimiter instead of 2 × 268px). Upstream reads `showTimeSelect` from its start and end controls; blocks can't be inspected, so pass it here. |
| `@shadow` | `boolean` | `true` | With `@inline`: a shadow around both calendars. |

| Block | Description |
| --- | --- |
| `<:start>` | The start input; yields the classes to give it. |
| `<:end>` | The end input; yields the classes to give it. |
| `<:prepend>` | Content before the inputs, e.g. an `EuiFormLabel` (upstream `prepend`); yields the class to put on it. Not rendered `@inline`. |
| `<:append>` | Content after the inputs (upstream `append`); yields the class to put on it. Not rendered `@inline`. |
| default block | Anything else, instead of the start and end blocks. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
