---
order: 2
---

# Empty

<EuiText>

Empty buttons are for **complementary (tertiary)** actions like close, cancel, filter, and refresh, which typically affect data presentation rather than modification. They reduce a button's visual importance and support the `xs` size and the `@flush` argument for alignment.

</EuiText>

```hbs template
<EuiFlexGroup @wrap={{true}} @gutterSize="s" @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty>Empty button</EuiButtonEmpty>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty @size="s">Small empty button</EuiButtonEmpty>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty @size="xs">Extra small empty button</EuiButtonEmpty>
  </EuiFlexItem>
</EuiFlexGroup>
```
