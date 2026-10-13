---
order: 2
---

# Semantic label relations

<EuiText>

HTML form elements (e.g. `<input>` or `<textarea>`) require a label for accessibility. If you're wrapping your component in an `EuiFormRow` with a `@label`, the label is automatically linked to the wrapped form control. If you're using a standalone form component (without a wrapping `EuiFormRow`) you'll need to manually ensure the form control has an accessible label.

To ensure the form control has an accessible label, you can pass `@id` on `EuiFormControlLayout` (or a form control like `EuiFieldText` or `EuiFieldNumber` that renders an `EuiFormControlLayout` internally). This renders non-interactive prepend or append content automatically as a semantically linked `<label>` element. You can also use `@inputId` on `EuiFormPrepend` or `EuiFormAppend` to link the content as label to a specific form control.

If you're using both prepend and append but don't want both automatically linked as label when passing `@id`, use `@inputId=""` on either `EuiFormPrepend` or `EuiFormAppend` to unset one of them.

If you don't pass an `@id`, the non-interactive prepend and append content will then be rendered as a simple, non-linked `<span>` element. To ensure your form control has an accessible label anyway, pass an `aria-label` or `aria-labelledby` to the form control (e.g. `EuiFieldText` or `EuiFieldNumber`).

</EuiText>

```gjs component
import {
  EuiFieldText,
  EuiFormAppend,
  EuiFormPrepend,
  EuiSpacer,
} from '@ember-eui/core/components';

<template>
  <EuiFieldText @id="input-id" placeholder="Text field">
    <:prepend><EuiFormPrepend @label="Linked label" /></:prepend>
    <:append><EuiFormAppend @label="Additional text" @inputId="" /></:append>
  </EuiFieldText>

  <EuiSpacer @size="m" />

  <EuiFieldText placeholder="Text field" aria-labelledby="prepend-id">
    <:prepend><EuiFormPrepend @label="Custom linked label" @id="prepend-id" /></:prepend>
  </EuiFieldText>

  <EuiSpacer @size="m" />

  <EuiFieldText placeholder="Text field" aria-label="Input label">
    <:prepend><EuiFormPrepend @label="Non-linked text" /></:prepend>
  </EuiFieldText>
</template>
```
