---
order: 12
---

# Flex grids and flex groups can nest

```hbs template
<div>
  <EuiFlexGroup class="flex-demo">
    <EuiFlexItem @grow={{false}}>
      <div>Flex Group</div>
      <EuiSpacer />
      <EuiFlexGroup class="flex-demo">
        <EuiFlexItem>Nested Grid One</EuiFlexItem>
        <EuiFlexItem>Nested Grid Two</EuiFlexItem>
      </EuiFlexGroup>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <div>Flex Grid</div>
      <EuiSpacer />
      <EuiFlexGrid @columns={{3}}>
        <EuiFlexItem>Nested Grid One</EuiFlexItem>
        <EuiFlexItem>Nested Grid Two</EuiFlexItem>
        <EuiFlexItem>Nested Grid Three</EuiFlexItem>
        <EuiFlexItem>Nested Grid Four</EuiFlexItem>
      </EuiFlexGrid>
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```