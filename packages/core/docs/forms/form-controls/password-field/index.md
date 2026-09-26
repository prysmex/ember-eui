---
title: Password field
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Password field"/>

<EuiSpacer />

<EuiText>
  <p>
    Use a <strong>EuiFieldPassword</strong> to allow users to enter a password.
    By default, it renders a basic HTML <EuiCode @language="html">{{'<input type="password">'}}</EuiCode> where the content is obfuscated.
    When users type in the field the characters are presented as asterisks.
  </p>
  <p>
    You can change this default behavior by passing <EuiCode>{{'@type="dual"'}}</EuiCode> so that users can toggle between showing and obfuscating the content.
    This option makes the experience more user-friendly and accessible.
  </p>
</EuiText>

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
