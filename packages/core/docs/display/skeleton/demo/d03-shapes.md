---
order: 3
---

# Circle and rectangle

<EuiText>

`EuiSkeletonCircle` comes in sizes `'s'`, `'m'`, `'l'` and `'xl'`.
`EuiSkeletonRectangle` takes any `@width` and `@height` (numbers are px,
24px by default) and an `@borderRadius` of `'s'`, `'m'` or `'none'`.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="center" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}><EuiSkeletonCircle @size="s" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiSkeletonCircle @size="m" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiSkeletonCircle @size="l" /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiSkeletonCircle @size="xl" /></EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @alignItems="center" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}><EuiSkeletonRectangle /></EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSkeletonRectangle @width={{120}} @height={{32}} @borderRadius="m" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSkeletonRectangle @width="200px" @height="100px" @borderRadius="none" />
  </EuiFlexItem>
</EuiFlexGroup>
```
