---
title: Password field
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Password field"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Wrap your form controls in a form row" @iconType="info" @size="s">
  <p>Use <code>EuiFormRow</code> to easily and accessibly associate form components with labels, help text and error text. Keep in mind that <code>EuiFormRow</code> controls the <code>id</code> of its wrapped child form component to associate it with the label and help text.</p>
</EuiCallOut>
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
| `@type` | `'dual' \| 'text' \| 'password'` | `'dual'` (upstream defaults to `'password'`) | `'password'` hides the text, `'text'` shows it, `'dual'` hides it with a button to show it. |
| `@fullWidth` | `boolean` |  | Stretches the input to its container's width. |
| `@compressed` | `boolean` |  | Shorter input (32px instead of 40px), for dense forms. |
| `@isLoading` | `boolean` |  | Shows a spinner in the input. |
| `@readOnly` | `boolean` |  | Makes the input read-only. |
| `@disabled` | `boolean` |  | Disables the input. |
| `@isInvalid` | `boolean` |  | Shows the invalid state (danger border and warning icon), sets `aria-invalid` and marks the input invalid for native form validation. |
| `@clear` |  |  | Shows a clear ("x") button calling this function; empty the value there. |
| `@inputRef` | `(element: HTMLInputElement) => void` |  | Called with the `<input>` element once rendered. |
| `@placeholder` | `string` |  | Placeholder text. |
| `@dualToggleProps` | `EuiFieldPasswordDualToggleProps` |  | Extra props for the `@type="dual"` show/mask button, an `EuiButtonIcon` (upstream `dualToggleProps`): `iconType`, `iconSize`, `color`, `display`, `size`, `isDisabled` / `disabled`, `css`, `id`, `className`, `aria-label` and `data-test-subj` replace the defaults; `onClick` is called after the toggle. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. |
| `<:append>` | Content after the input; yields the class to put on it and the input id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
