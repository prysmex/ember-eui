---
order: 9
---

# Change direction

<EuiText>

`@direction="column"` stacks the items vertically (`columnReverse` and `rowReverse` reverse the order).

</EuiText>

```hbs template
<EuiFlexGroup class="flex-demo" @direction="column">
  <EuiFlexItem @grow={{false}}>Content grid item</EuiFlexItem>
  <EuiFlexItem @grow={{false}}>Another content grid item</EuiFlexItem>
  <EuiFlexItem @grow={{false}}>Using the column direction</EuiFlexItem>
</EuiFlexGroup>
```