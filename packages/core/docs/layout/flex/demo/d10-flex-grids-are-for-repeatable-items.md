---
order: 10
---

# Flex grids are for repeatable items

<EuiText>

`EuiFlexGrid` lays out many similar items in `@columns` (1 to 4) of equal width. Use it for repeated content like cards; for layout use `EuiFlexGroup`.

</EuiText>

```hbs template
<div>
  <EuiFlexGrid class="flex-demo" @columns={{3}}>
    <EuiFlexItem>
      <div>One</div>
    </EuiFlexItem>
    <EuiFlexItem>
      <div>Two</div>
    </EuiFlexItem>
    <EuiFlexItem>
      <div>Three</div>
    </EuiFlexItem>
    <EuiFlexItem>
      <div>Four</div>
    </EuiFlexItem>
    <EuiFlexItem>
      <div>Five</div>
    </EuiFlexItem>
    <EuiFlexItem>
      <div>Six</div>
    </EuiFlexItem>
    <EuiFlexItem>
      <div>Seven</div>
    </EuiFlexItem>
  </EuiFlexGrid>
</div>
```