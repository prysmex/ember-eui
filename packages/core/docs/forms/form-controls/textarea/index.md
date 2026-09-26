---
title: Textarea
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Textarea"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiTextArea` renders a `<textarea>` for multi-line text. `@rows` sets its
height in lines and `@resize` which way the user can resize it. For
formatted text, see the markdown editor.

```hbs
<EuiFormRow @label="Description" @helpText="Markdown is not supported here.">
  <EuiTextArea @value={{this.description}} @rows={{4}} {{on "input" this.updateDescription}} />
</EuiFormRow>
```

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTextArea

A multi-line text input. Attributes (`placeholder`, `maxlength`…) go to the `<textarea>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the textarea. |
| `@value` | `string` |  | The value. Update it from `{{on "input" …}}`. |
| `@fullWidth` | `boolean` |  | Stretches the textarea to its container's width. |
| `@compressed` | `boolean` |  | Smaller textarea, for dense forms. |
| `@disabled` | `boolean` |  | Disables the textarea. |
| `@isInvalid` | `boolean` |  | Shows the invalid state and marks it invalid for native form validation. |
| `@inputRef` | `(element: HTMLTextAreaElement \| null) => void` |  | Called with the `<textarea>` element once rendered. |
| `@rows` | `number` |  | Visible number of lines. |
| `@resize` |  | `'vertical'` | Which way the user can resize it: `'vertical'`, `'horizontal'`, `'both'` or `'none'`. |
| `@readOnly` | `boolean` |  | Makes the textarea read-only. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<textarea>`.

</EuiText>
<!-- api:end -->
