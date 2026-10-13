---
order: 7
---

# Implicit titles for the first form control

<EuiText>

When displaying the form control's name in some other way than through the visual `@label`, the form control still needs to be associated with that element. To do this, either:

- duplicate the text and pass it as the `aria-label` of the form control, or
- pass the `id` of the text to the form control's `aria-labelledby`.

</EuiText>

```gjs component
import {
  EuiCode,
  EuiDescribedFormGroup,
  EuiFieldText,
  EuiFilePicker,
  EuiForm,
  EuiFormRow,
} from '@ember-eui/core/components';

<template>
  <EuiForm>
    <EuiDescribedFormGroup>
      <:title><span id="implicitTitle">Implicit titles</span></:title>
      <:description>
        <strong>EuiDescribedFormGroup</strong> components tend to use this
        pattern as the title and label are usually the same.
      </:description>
      <:default>
        <EuiFormRow>
          <:helpText>
            A screen reader will still know the name of this input because we
            used <EuiCode>aria-labelledby</EuiCode> here to point to the
            <strong>EuiDescribedFormGroup</strong> title <EuiCode>id</EuiCode>.
          </:helpText>
          <:field>
            <EuiFieldText aria-labelledby="implicitTitle" />
          </:field>
        </EuiFormRow>
        <EuiFormRow>
          <:helpText>
            Here we passed in the <strong>EuiDescribedFormGroup</strong> title
            text into a <EuiCode>aria-label</EuiCode> on
            <strong>EuiFilePicker</strong>.
          </:helpText>
          <:field>
            <EuiFilePicker aria-label="Implicit titles" />
          </:field>
        </EuiFormRow>
      </:default>
    </EuiDescribedFormGroup>
  </EuiForm>
</template>
```
