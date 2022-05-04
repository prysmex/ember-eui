---
order: 14
---

# Responsive layouts

```hbs template
<div>
  <EuiFlexGroup class="flex-demo" @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiIcon @type="faceSad" />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      On mobile, the icon will show above this text.
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer />

  <EuiFlexGroup class="flex-demo" @responsive={{false}} @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiIcon @type="faceHappy" />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      On mobile, the icon will stay to the left of this text.
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```