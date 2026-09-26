---
title: Search field
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Search field"/>

<EuiSpacer />

<EuiText>
  <p>
    This component renders a basic HTML <EuiCode @language="html">{{'<input type="search">'}}</EuiCode> element.
    Use a <strong>EuiFieldSearch</strong> to allow users to enter search queries.
  </p>
</EuiText>

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
