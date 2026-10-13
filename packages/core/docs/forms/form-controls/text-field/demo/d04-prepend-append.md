---
order: 4
---

# Prepend and append

<EuiText>

The `<:prepend>` and `<:append>` blocks put content before or after the
input, joined to it: labels (`EuiFormLabel`), units, or buttons. Each block
yields a class to put on what you render, so it is styled as part of the
field, and the input's id.

</EuiText>

```gjs component
import { EuiFormRow, EuiFieldText, EuiFormLabel, EuiButtonEmpty } from '@ember-eui/core/components';

<template>
  <EuiFormRow @label="Website">
    <EuiFieldText @value="example">
      <:prepend as |classes inputId|>
        <EuiFormLabel class={{classes}} for={{inputId}}>https://</EuiFormLabel>
      </:prepend>
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>.com</EuiFormLabel>
      </:append>
    </EuiFieldText>
  </EuiFormRow>

  <EuiFormRow @label="Invite">
    <EuiFieldText @value="jane@example.com">
      <:append as |classes|>
        <EuiButtonEmpty class={{classes}} @size="xs" @iconType="plusInCircle">
          Add
        </EuiButtonEmpty>
      </:append>
    </EuiFieldText>
  </EuiFormRow>
</template>
```
