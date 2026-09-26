---
order: 2
---

# Flex items are also flex

<EuiText>

An `EuiFlexItem` is itself a flex column, so a button inside it stretches to the item's width. Wrap it in a `<div>` to keep its natural width.

</EuiText>

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