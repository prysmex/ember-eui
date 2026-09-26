---
order: 3
---

# Invalid, loading, compressed and disabled

<EuiText>

The same states as the other fields: `@isInvalid`, `@isLoading`,
`@compressed`, `@readOnly` and `@disabled`.

</EuiText>

```hbs template
<EuiFlexGrid @columns={{2}}>
  <EuiFlexItem>
    <EuiFormRow @label="Invalid" @isInvalid={{true}} @error="Must be 18 or more.">
      <EuiFieldNumber @value="12" @isInvalid={{true}} />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Loading">
      <EuiFieldNumber @value="4" @isLoading={{true}} />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Compressed" @display="rowCompressed">
      <EuiFieldNumber @value="4" @compressed={{true}} />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Disabled">
      <EuiFieldNumber @value="4" @disabled={{true}} />
    </EuiFormRow>
  </EuiFlexItem>
</EuiFlexGrid>
```
