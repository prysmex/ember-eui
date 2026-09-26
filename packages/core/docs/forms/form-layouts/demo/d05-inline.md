---
order: 5
---

# Inline forms

<EuiText>

Lay rows out side by side with `EuiFlexGroup`. `@hasEmptyLabelSpace` on the
row holding the button adds the space a label would take, so the button
lines up with the fields.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="flexStart">
  <EuiFlexItem>
    <EuiFormRow @label="First name">
      <EuiFieldText />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Last name">
      <EuiFieldText />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiFormRow @hasEmptyLabelSpace={{true}}>
      <EuiButton>Invite</EuiButton>
    </EuiFormRow>
  </EuiFlexItem>
</EuiFlexGroup>
```
