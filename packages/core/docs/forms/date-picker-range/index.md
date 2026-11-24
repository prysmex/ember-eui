---
title: Date picker range
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Date picker range"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiDatePickerRange` joins a start and an end date input into one field
with an arrow between them. Put an
[`EuiDatePicker`](/docs/core/docs/forms/date-picker) in each of its
`<:start>` and `<:end>` blocks, with the class the block yields:

```hbs
<EuiDatePickerRange @isInvalid={{this.endBeforeStart}}>
  <:start as |className|>
    <EuiDatePicker
      class={{className}}
      aria-label="Start date"
      @value={{this.start}}
      @onChange={{this.setStart}}
      @selectsStart={{true}}
      @startDate={{this.start}}
      @endDate={{this.end}}
      @maxDate={{this.end}}
    />
  </:start>
  <:end as |className|>
    <EuiDatePicker
      class={{className}}
      aria-label="End date"
      @value={{this.end}}
      @onChange={{this.setEnd}}
      @selectsEnd={{true}}
      @startDate={{this.start}}
      @endDate={{this.end}}
      @minDate={{this.start}}
    />
  </:end>
</EuiDatePickerRange>
```

A picker in a block takes its place in the range by itself, as upstream's
`startDateControl` and `endDateControl` do:

- it renders without a frame or an icon of its own: the range draws them;
- it takes the range's `@inline`, `@compressed`, `@fullWidth` and
  `@readOnly`, unless it sets them itself; its own `@disabled` and
  `@isInvalid` add to the range's;
- the end picker opens its calendar aligned to the right (`downRight`);
- in an inline range, a picker with `@showTimeSelect` makes the range stack
  the two calendars below a wider container.

With `@isCustom={{true}}` the range passes nothing to the pickers.

</EuiText>

<EuiHorizontalRule />

<EuiText>

## The range highlight

Give both pickers `@startDate` and `@endDate`: each calendar then
highlights the days from the start to the end. With `@selectsStart` on the
start picker and `@selectsEnd` on the end picker, the calendar previews the
range a pick would make, from the day under the mouse or the focused day.
They take what `@value` takes: `YYYY-MM-DD`, an instant (highlighted by its
day in `@timeZone`), a `Date` or a moment.

The range does not check that the end is after the start. Limit each
picker with `@minDate` and `@maxDate`, as above, or mark the range
`@isInvalid`.

## On phones

On a phone each picker renders the operating system's own date input, as
a picker outside a range does (see
[Date picker](/docs/core/docs/forms/date-picker), "Phones and Capacitor").
Inside the range it keeps the browser's own calendar indicator, since the
range draws EUI's icon; an inline range always shows the calendars.

## Other date inputs

The blocks take any date input: `EuiFlatpickr` from
`@ember-eui/flatpickr`, `EuiPikaday` from `@ember-eui/pikaday`, or a native
`<EuiFieldText type="date">`. Render it with `@controlOnly={{true}}` and
the class its block yields. These inputs do not read the range's states:
pass `@disabled`, `@isInvalid` and the rest to them as well.

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
`EuiFormControlLayoutDelimited`). An `EuiDatePicker` in the `<:start>`
or `<:end>` block takes the range's states by itself, as upstream's
`startDateControl` and `endDateControl`: no frame of its own, no icon,
`@inline`, `@compressed`, `@fullWidth`, `@readOnly`, `@disabled` and
`@isInvalid`, and the end opens its calendar `downRight`. Any other date
input works too (`EuiFlatpickr`, `EuiPikaday`,
`<EuiFieldText type="date">`): render it with `@controlOnly={{true}}`
and the class its block yields.

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
| `@isCustom` | `boolean` |  | Custom controls: the `<:start>` / `<:end>` blocks yield only the delimited input class, without the date picker range classes, and an `EuiDatePicker` in them takes nothing from the range (upstream doesn't add its props to the controls). |
| `@delimiter` | `string` | an arrow icon labelled "to" | Text between the inputs. |
| `@inline` | `boolean` |  | Two calendars displayed in the page: drops the field frame, the icon and `@fullWidth`/`@compressed`, lays the blocks out side by side and stacks them when the container is too narrow. An `EuiDatePicker` in a block becomes inline by itself; pass the inline option to other calendars (`EuiFlatpickr`, `EuiPikaday`). |
| `@showTimeSelect` | `boolean` |  | With `@inline`: the calendars show a time list, so they stack below a wider container (2 × 374px + the delimiter instead of 2 × 268px). An `EuiDatePicker` with `@showTimeSelect` tells the range by itself, as upstream reads it from its controls; pass it for other calendars. |
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
