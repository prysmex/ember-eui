---
order: 4
---

# Chart and Elastic logo

<EuiText>

`EuiLoadingChart` stands in for a chart while its data loads (`@mono` for
gray bars); `EuiLoadingElastic` animates the Elastic logo for a full page.
Give them an `aria-label` so screen readers announce what is loading.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="center" @gutterSize="xl">
  <EuiFlexItem @grow={{false}}>
    <EuiLoadingChart @size="xl" aria-label="Loading chart" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiLoadingChart @size="xl" @mono={{true}} aria-label="Loading chart" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiLoadingElastic @size="xxl" aria-label="Loading" />
  </EuiFlexItem>
</EuiFlexGroup>
```
