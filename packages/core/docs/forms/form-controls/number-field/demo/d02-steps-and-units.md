---
order: 2
---

# Decimals and units

<EuiText>

`@step` sets the increment (`"any"` allows any decimal). Show a unit with
the `<:append>` block (or a currency with `<:prepend>`); each block yields
a class to put on its content.

</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiFormRow @label="Weight">
      <EuiFieldNumber @value="72.5" @step={{0.1}}>
        <:append as |classes|>
          <EuiFormLabel class={{classes}}>kg</EuiFormLabel>
        </:append>
      </EuiFieldNumber>
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Price">
      <EuiFieldNumber @value="19.99" @step="any">
        <:prepend as |classes|>
          <EuiFormLabel class={{classes}}>$</EuiFormLabel>
        </:prepend>
      </EuiFieldNumber>
    </EuiFormRow>
  </EuiFlexItem>
</EuiFlexGroup>
```
