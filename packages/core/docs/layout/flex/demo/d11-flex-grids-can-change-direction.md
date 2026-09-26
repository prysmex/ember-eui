---
order: 11
---

# Flex grids can change direction

<EuiText>

With `@direction="column"`, a grid fills its columns top to bottom instead of row by row.

</EuiText>

```hbs template
<div>
  <EuiFlexGrid class="flex-demo" @columns={{2}} @direction="column">
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