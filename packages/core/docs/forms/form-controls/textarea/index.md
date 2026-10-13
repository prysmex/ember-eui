---
title: Textarea
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Textarea"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Wrap your form controls in a form row" @iconType="info" @size="s">
  <p>Use <code>EuiFormRow</code> to easily and accessibly associate form components with labels, help text and error text. Keep in mind that <code>EuiFormRow</code> controls the <code>id</code> of its wrapped child form component to associate it with the label and help text.</p>
</EuiCallOut>
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
| `@compressed` | `boolean` |  | Tighter padding (8px instead of 12px) and 3 default rows, for dense forms. |
| `@disabled` | `boolean` |  | Disables the textarea. |
| `@isInvalid` | `boolean` |  | Shows the invalid state (danger border), sets `aria-invalid` and marks it invalid for native form validation. |
| `@inputRef` | `(element: HTMLTextAreaElement \| null) => void` |  | Called with the `<textarea>` element once rendered. |
| `@rows` | `number` | 6, or 3 when `@compressed` | Visible number of lines. |
| `@resize` | `EuiTextAreaResize` | `'vertical'` | Which way the user can resize it: `'vertical'`, `'horizontal'`, `'both'` or `'none'`. |
| `@readOnly` | `boolean` |  | Makes the textarea read-only. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<textarea>`.

</EuiText>
<!-- api:end -->
