---
order: 1
---

```hbs template
<EuiDescribedFormGroup>
  <:title>
    <h3>
      Set heading level based on context
    </h3>
  </:title>
  <:description>
    Will be wrapped in a small, subdued EuiText block.
  </:description>
  <:default>
    <EuiFormRow @label='Text field'>
      <EuiFieldText />
    </EuiFormRow>
  </:default>
</EuiDescribedFormGroup>
<EuiDescribedFormGroup>
  <:title>
    <h3>
      No description
    </h3>
  </:title>
  <:default>
    <EuiFormRow @label='Text field'>
      <EuiFieldText />
    </EuiFormRow>
  </:default>
</EuiDescribedFormGroup>
<EuiDescribedFormGroup>
  <:title>
    <h3>
      Multiple fields
    </h3>
  </:title>
  <:description>
    Here are three form rows. The first form row does not have a title.
  </:description>
  <:default>
    <EuiFormRow @label='Text field'>
      <EuiFieldText />
    </EuiFormRow>
    <EuiFormRow @label='Text field'>
      <EuiFilePicker />
    </EuiFormRow>
    <EuiFormRow @label='Text field'>
      <EuiRangeSlider />
    </EuiFormRow>

  </:default>
</EuiDescribedFormGroup>
<EuiDescribedFormGroup @fullWidth={{true}}>
  <:title>
    <h3>
      Full width
    </h3>
  </:title>
  <:description>
    By default, EuiDescribedFormGroup will be double the default width of form elements. However, you can pass fullWidth prop to this, the individual field and row components to expand to their container.
  </:description>
  <:default>
    <EuiFormRow @label='Use a switch instead of a single checkbox'>
      <EuiSwitch />
    </EuiFormRow>
    <EuiFormRow @label='Text field'>
      <EuiFieldText />
    </EuiFormRow>
  </:default>
</EuiDescribedFormGroup>
```
