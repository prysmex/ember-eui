---
order: 15
---

# Align

<EuiText>

Flex grids support vertically aligning children via the `@alignItems` arg. Unlike flex groups, they do not support `@justifyContent`, as grid columns are always evenly distributed.

</EuiText>

```hbs template
<EuiFlexGrid class="flex-demo" @columns={{2}} @alignItems="center">
  <EuiFlexItem>I<br />am<br />a<br />tall<br />item</EuiFlexItem>
  <EuiFlexItem>I am vertically centered!</EuiFlexItem>
</EuiFlexGrid>
```
