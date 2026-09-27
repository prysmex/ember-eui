---
title: Number field
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Number field"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiFieldNumber` renders an `<input type="number">`: arrows and the
keyboard's up/down keys change the value by `@step`, within `@min` and
`@max`. Like every EUI control, it shows `@value` and you update it from
the `input` event. Note that `event.target.value` is a **string** (empty
when the field is cleared): convert it with `Number()` or
`event.target.valueAsNumber` when you need a number.

```hbs
<EuiFormRow @label="Quantity">
  <EuiFieldNumber @value={{this.quantity}} @min={{1}} @max={{99}} {{on "input" this.updateQuantity}} />
</EuiFormRow>
```

For picking a number on a scale, see the range slider.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFieldNumber

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the input, e.g. to match an `EuiFormRow`'s label. |
| `@icon` | `IconType` |  | Icon inside the input, anything `EuiIcon`'s `@type` accepts. |
| `@isInvalid` | `boolean` |  | Shows the invalid state and marks the input invalid for native form validation. |
| `@fullWidth` | `boolean` |  | Stretches the input to its container's width. |
| `@isLoading` | `boolean` |  | Shows a spinner in the input. |
| `@readOnly` | `boolean` |  | Makes the input read-only. |
| `@min` | `number \| string` |  | Lowest allowed value. |
| `@max` | `number \| string` |  | Highest allowed value. |
| `@value` | `number \| string` |  | The value. Update it from `{{on "input" …}}` (the event's value is a string). |
| `@disabled` | `boolean` |  | Disables the input. |
| `@step` | `number \| 'any'` |  | Specifies the granularity that the value must adhere to. Accepts a `number` or the string `'any'` for no stepping to allow for any value. Defaults to `1` |
| `@inputRef` | `(ele: Element) => void` |  | Called with the `<input>` element once rendered. |
| `@controlOnly` | `boolean` |  | Completely removes form control layout wrapper and ignores icon, prepend, and append. Best used inside EuiFormControlLayoutDelimited. |
| `@compressed` | `boolean` |  | Shorter input, for dense forms. |
| `@clear` |  |  | Shows a clear ("x") button calling this function; empty the value there. |

Deprecated: `@prepend` (Has no effect, use the `<:prepend>` block.); `@append` (Has no effect, use the `<:append>` block.).

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it. |
| `<:append>` | Content after the input, e.g. a unit; yields the class to put on it. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
