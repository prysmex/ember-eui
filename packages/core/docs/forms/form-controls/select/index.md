---
title: Select
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Select"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Wrap your form controls in a form row" @iconType="info" @size="s">
  <p>Use <code>EuiFormRow</code> to easily and accessibly associate form components with labels, help text and error text. Keep in mind that <code>EuiFormRow</code> controls the <code>id</code> of its wrapped child form component to associate it with the label and help text.</p>
</EuiCallOut>
<EuiSpacer @size="l" />

<EuiText>

`EuiSelect` renders a native `<select>` styled like the other fields.
Options are `{ value, text }`; `@value` is the selected option's value and
you update it from the `change` event.

```hbs
<EuiFormRow @label="Country">
  <EuiSelect @options={{this.countries}} @value={{this.country}} {{on "change" this.chooseCountry}} />
</EuiFormRow>
```

Use it for about 7 to 12 options. For fewer, radios show every choice at
once; for long lists, searching or several values, use `EuiComboBox`.
`@hasNoInitialSelection` adds an empty first option so nothing is picked
until the user chooses.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSelect

A native `<select>` styled like EUI's inputs. For search or multiple values use EuiComboBox.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the select. |
| `@options` (required) |  |  | The options: `[{ value: 'a', text: 'Option A', disabled? }]`. |
| `@value` | `string \| number \| null` |  | The selected option's `value`. Update it from `{{on "change" …}}`. `null` selects nothing, like leaving it out. |
| `@fullWidth` | `boolean` |  | Stretches the select to its container's width. |
| `@compressed` | `boolean` |  | Shorter select (32px instead of 40px), for dense forms. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@disabled` | `boolean` |  | Disables the select. |
| `@hasNoInitialSelection` | `boolean` | `false` | Adds an empty first option, selected while `@value` is empty, so no option is preselected. |
| `@isInvalid` | `boolean` |  | Shows the invalid state (danger border and warning icon), sets `aria-invalid` and marks it invalid for native form validation. |
| `@clear` | `(v: any) => void` |  | Shows a clear ("x") button calling this function. |
| `@inputRef` | `(element: HTMLSelectElement) => void` |  | Called with the `<select>` element once rendered. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the select; yields the class to put on it and the id. |
| `<:append>` | Content after the select; yields the class to put on it and the id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<select>`.

</EuiText>
<!-- api:end -->
