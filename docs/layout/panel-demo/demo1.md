# Demo

```hbs template
<EuiFlexGroup @direction="column" @gutterSize="xl">
  <EuiFlexItem>
    <EuiPanel @color="danger">
      This is panel without borders
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @borderRadius="none" @color="danger">
      This is panel without border radius
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @borderRadius="none" @paddingSize="none" @color="danger">
      This is panel without padding and without border-radius
    </EuiPanel>
  </EuiFlexItem>
</EuiFlexGroup>
```