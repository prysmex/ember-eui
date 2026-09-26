---
title: Range
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Range"/>

<EuiSpacer />

<EuiText>
  <EuiCallOut @color="warning" @title="Understanding precision">
    <:body>
      <p>
        Range sliders should only be used when <strong>the precise value is not considered important</strong>.
        If the precise value does matter, add the <EuiCode>@showInput</EuiCode> arg or use a <strong>EuiFieldNumber</strong> instead.
      </p>
    </:body>
  </EuiCallOut>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiRange

A slider to pick a number, optionally with a number input, ticks,
levels and a value tooltip. For a range of two values use EuiDualRange.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@compressed` | `boolean` | `false` | Smaller slider, for dense forms. |
| `@readOnly` | `boolean` |  | Makes the number input read-only. |
| `@fullWidth` | `boolean` | `false` | Stretches the slider to its container's width. |
| `@id` | `string` | a generated id | Id of the slider. |
| `@levels` | `EuiRangeLevel[]` |  | Create colored indicators for certain intervals |
| `@step` | `number` | `1` | Increment between values. |
| `@showInput` | `boolean \| 'inputWithPopover'` |  | Pass `true` to displays an extra input control for direct manipulation. Pass `'inputWithPopover'` to only show the input but show the range in a dropdown. |
| `@showLabels` | `boolean` | `false` | Shows static min/max labels on the sides of the range slider. |
| `@showRange` | `boolean` | `false` | Shows a thick line from min to value. |
| `@showTicks` | `boolean` | `false` | Shows clickable tick marks and labels at the given interval (`step`/`tickInterval`). |
| `@min` | `number` | `0` | Lowest selectable value. |
| `@max` | `number` | `100` | Highest selectable value. |
| `@showValue` | `boolean` | `false` | Shows the value in a tooltip above the thumb. |
| `@ticks` | `EuiRangeTick[]` |  | Specified ticks at specified values |
| `@tickInterval` | `number` |  | Modifies the number of tick marks and at what interval |
| `@valueAppend` | `any` |  | Appends to the tooltip |
| `@valuePrepend` | `any` |  | Prepends to the tooltip |
| `@onChange` | `(event: Event, isValid: boolean) => void` |  | Called with the event (read `event.target.value`, a string) and whether the value is within `@min`/`@max`. Update `@value` here. |
| `@onBlur` | `(event: Event) => void` |  | Called when the slider or input loses focus. |
| `@onFocus` | `(event: Event) => void` |  | Called when the slider or input gets focus. |
| `@value` | `number` |  | The value. |
| `@disabled` | `boolean` |  | Disables the slider and input. |
| `@isInvalid` | `boolean` |  | Shows the invalid state. |
| `@name` | `string` |  | `name` of the inputs, for forms. |
| `@isLoading` | `boolean` | `false` | Shows a spinner in the number input. |

| Block | Description |
| --- | --- |
| `<:min>` | Custom min label (`@showLabels`); yields `@min`. |
| `<:max>` | Custom max label (`@showLabels`); yields `@max`. |
| `<:value>` | Custom value tooltip content (`@showValue`). |
| `<:valueAppend>` | Content after the value in the tooltip, e.g. a unit. |
| `<:valuePrepend>` | Content before the value in the tooltip, e.g. a currency sign. |
| `<:prepend>` | Content before the number input (`@showInput`); yields its class. |
| `<:append>` | Content after the number input (`@showInput`); yields its class. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

### EuiDualRange

A slider with two thumbs to pick a range, e.g. a price range. For one
value use EuiRange.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@value` (required) | `[ValueMember, ValueMember]` |  | The selected range, `[lower, upper]`. Update it in `@onChange`. |
| `@onBlur` | `(event: FocusEvent) => void` |  | Called when a thumb or input loses focus. |
| `@onFocus` | `(event: FocusEvent) => void` |  | Called when a thumb or input gets focus. |
| `@onChange` (required) |  |  | Called with the new `[lower, upper]` values, whether they are valid (within `@min`/`@max` and lower ≤ upper) and the event. |
| `@fullWidth` | `boolean` |  | Stretches the slider to its container's width. |
| `@isInvalid` | `boolean` |  | Shows the invalid state. |
| `@levels` | `EuiRangeLevel[]` |  | Create colored indicators for certain intervals: `[{ min: 0, max: 20, color: 'danger' }, …]`. |
| `@showLabels` | `boolean` | `false` | Shows static min/max labels on the sides of the range slider. |
| `@showInput` | `EuiRangeArgs['showInput']` |  | Pass `true` to displays an extra input control for direct manipulation. Pass `'inputWithPopover'` to only show the input but show the range in a dropdown. |
| `@tickInterval` | `number` |  | Modifies the number of tick marks and at what interval |
| `@ticks` | `EuiRangeTick[]` |  | Specified ticks at specified values: `[{ label: '20kb', value: 20 }]`. |
| `@readOnly` | `boolean` |  | Makes the inputs read-only. |
| `@disabled` | `boolean` |  | Disables the slider and inputs. |
| `@disable` | `boolean` |  | Disables the number inputs. |
| `@ariaDescribedby` | `string` |  | Id of the element(s) describing the slider thumbs. |
| `@ariaLabel` | `string` |  | Accessible label of the slider thumbs. |
| `@name` | `string` |  | `name` of the inputs; the number inputs get `-minValue` / `-maxValue` suffixes. |
| `@id` | `string` | a generated id | Id of the slider. |
| `@compressed` | `boolean` | `false` | Smaller slider, for dense forms. |
| `@showRange` | `boolean` | `true` | Highlights the selected range on the track. |
| `@showTicks` | `boolean` | `false` | Shows tick marks, every `@step` (or `@tickInterval`). |
| `@step` | `number` | `1` | Increment between values. |
| `@min` | `number` | `0` | Lowest selectable value. |
| `@max` | `number` | `100` | Highest selectable value. |

Deprecated: `@prepend` (Has no effect, use the `<:prepend>` block (shown with `@showInput="inputWithPopover"`).); `@append` (Has no effect, use the `<:append>` block (shown with `@showInput="inputWithPopover"`).); `@minInputProps` (Has no effect.); `@maxInputProps` (Has no effect.).

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the inputs (`@showInput="inputWithPopover"`). |
| `<:append>` | Content after the inputs (`@showInput="inputWithPopover"`). |
| `<:min>` | Custom min label (`@showLabels`); yields `@min`. |
| `<:max>` | Custom max label (`@showLabels`); yields `@max`. |

</EuiText>
<!-- api:end -->
