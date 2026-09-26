---
title: Textarea
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Textarea"/>

<EuiSpacer />

<EuiText>
  <p>
    This component renders a basic HTML <EuiCode @language="html">{{'<textarea />'}}</EuiCode> element.
    Use <strong>EuiTextArea</strong> to allow users to enter multi-line text.
  </p>
</EuiText>

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
