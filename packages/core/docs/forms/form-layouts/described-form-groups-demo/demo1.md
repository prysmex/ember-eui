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
```
