---
title: Password field
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Password field"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiFieldPassword` is an input for passwords and other secrets. By default
(`@type="dual"`) it hides the text and adds a button to show it, which
helps users check what they typed; `@type="password"` only hides it and
`@type="text"` shows it.

```hbs
<EuiFormRow @label="Password">
  <EuiFieldPassword
    @value={{this.password}}
    autocomplete="current-password"
    {{on "input" this.updatePassword}}
  />
</EuiFormRow>
```

Set `autocomplete` (`current-password` or `new-password`) so password
managers fill it in.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFieldPassword

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@value` | `string` |  | The value. Update it from `{{on "input" …}}` on the component. |
| `@id` | `string` | a random id | Id of the input, e.g. to match an `EuiFormRow`'s label. |
| `@type` | `'dual' \| 'text' \| 'password'` | `'dual'` | `'password'` hides the text, `'text'` shows it, `'dual'` hides it with a button to show it. |
| `@fullWidth` | `boolean` |  | Stretches the input to its container's width. |
| `@compressed` | `boolean` |  | Shorter input, for dense forms. |
| `@isLoading` | `boolean` |  | Shows a spinner in the input. |
| `@readOnly` | `boolean` |  | Makes the input read-only. |
| `@disabled` | `boolean` |  | Disables the input. |
| `@isInvalid` | `boolean` |  | Shows the invalid state and marks the input invalid for native form validation. |
| `@clear` |  |  | Shows a clear ("x") button calling this function; empty the value there. |
| `@inputRef` | `(element: HTMLInputElement) => void` |  | Called with the `<input>` element once rendered. |
| `@placeholder` | `string` |  | Placeholder text. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. |
| `<:append>` | Content after the input; yields the class to put on it and the input id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
