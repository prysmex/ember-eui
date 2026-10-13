---
order: 2
---

# Sizing described form rows

<EuiText>

By default, `EuiDescribedFormGroup` has a max-width of 800px for best readability. To expand the group to 100%, add `@fullWidth` to this, the `EuiFormRow`, **and** the individual fields.

</EuiText>

```gjs component
import {
  EuiDescribedFormGroup,
  EuiFieldText,
  EuiFilePicker,
  EuiForm,
  EuiFormRow,
} from '@ember-eui/core/components';

<template>
  <EuiForm @tagName="form">
    <EuiDescribedFormGroup @fullWidth={{true}} @titleTagName="h2">
      <:title>Full width</:title>
      <:description>
        The title and description will grow to fill the left side column at
        any width. Be mindful that it doesn't get too wide.
      </:description>
      <:default>
        <EuiFormRow
          @fullWidth={{true}}
          @label="Text field"
          @helpText="Be sure to add fullWidth to EuiFormRow and nested fields."
        >
          <EuiFieldText @fullWidth={{true}} name="first" aria-label="Example" />
        </EuiFormRow>
        <EuiFormRow @fullWidth={{true}} @label="File picker">
          <EuiFilePicker @fullWidth={{true}} />
        </EuiFormRow>
      </:default>
    </EuiDescribedFormGroup>
  </EuiForm>
</template>
```
