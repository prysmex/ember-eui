---
order: 2
---

# Flex items are also flex

```hbs template
<EuiFlexGroup class="flex-demo">
  <EuiFlexItem>
    <EuiButton @fill={{true}}>Buttons will widen</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem>
    <div>
      <EuiButton @fill={{true}}>Unless you wrap them</EuiButton>
    </div>
  </EuiFlexItem>
</EuiFlexGroup>
```