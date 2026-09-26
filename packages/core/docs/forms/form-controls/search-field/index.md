---
title: Search field
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Search field"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiFieldSearch` is a text input with a search icon and a clear button.
It calls `@onSearch` with the text when the user presses Enter or clears
the field, or on every keystroke with `@incremental={{true}}` (useful for
filtering lists as you type).

```hbs
<EuiFieldSearch
  @value={{this.query}}
  @onSearch={{this.search}}
  @incremental={{true}}
  placeholder="Search users"
  aria-label="Search users"
/>
```

Give it an accessible name (`aria-label`, or an `EuiFormRow` label).

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFieldSearch

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@value` | `string` |  | The search text. Update it in `@onSearch`. |
| `@defaultValue` | `string` |  | Initial text when `@value` is not passed. |
| `@incremental` | `boolean` |  | When `true` the search will be executed (that is, the `onSearch` will be called) as the user types. |
| `@onKeyUp` | `(e: KeyboardEvent) => void` |  | Called on keyup, before `@onSearch`; call `event.preventDefault()` to skip the search. |
| `@onSearch` (required) | `(value: string) => void` |  | Called with the text when the user presses Enter or clears the field, and on every keystroke with `@incremental`. |
| `@fullWidth` | `boolean` |  | Stretches the input to its container's width. |
| `@compressed` | `boolean` |  | Shorter input, for dense forms. |
| `@isLoading` | `boolean` |  | Shows a spinner in the input. |
| `@isClearable` | `boolean` | `true` | Shows a clear button while `@value` is set. |
| `@disabled` | `boolean` |  | Disables the input. |
| `@readOnly` | `boolean` |  | Hides the clear button. |
| `@placeholder` | `string` |  | Placeholder text. |
| `@id` | `string` | a random id | Id of the input, e.g. to match an `EuiFormRow`'s label. |
| `@isInvalid` | `boolean` |  | Shows the invalid state and marks the input invalid for native form validation. |
| `@isDisabled` | `boolean` |  | Hides the clear button; use `@disabled` to disable the input. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. |
| `<:append>` | Content after the input; yields the class to put on it and the input id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
