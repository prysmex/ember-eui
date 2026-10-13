---
order: 3
---

# Ratio of the description and field columns

<EuiText>

You can also change the ratio of the width of the description column versus the field column. By default it is `'half'`, but you can also change to `'third'` or `'quarter'` which prioritizes the field column. You will most likely still need to apply `@fullWidth` to all the components. The description column does have a minimum readable width applied to it so that it cannot shrink too far.

Both the description and field columns are simply `EuiFlexItem` wrappers. If you need more customization of these columns you can pass flex item arguments to `@descriptionFlexItemProps` and `@fieldFlexItemProps` respectively.

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
    <EuiDescribedFormGroup @ratio="third" @titleTagName="h2">
      <:title>Ratio of thirds</:title>
      <:description>
        The title and description will shrink to fit inside the left side but
        retains a readable minimum width.
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
