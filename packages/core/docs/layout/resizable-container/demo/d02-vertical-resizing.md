---
order: 2
---

# Vertical

<EuiText>

`@direction="vertical"` stacks the panels; the container needs a height.
Here three panels share it.

</EuiText>

```hbs template
<EuiResizableContainer @direction="vertical" style="height: 360px;" as |c|>
  <c.Panel @initialSize={{50}} @minSize="40px" @color="subdued">
    <EuiText @size="s"><p>Query</p></EuiText>
  </c.Panel>
  <c.Button />
  <c.Panel @initialSize={{30}} @minSize="40px">
    <EuiText @size="s"><p>Results</p></EuiText>
  </c.Panel>
  <c.Button />
  <c.Panel @initialSize={{20}} @minSize="40px">
    <EuiText @size="s"><p>Log</p></EuiText>
  </c.Panel>
</EuiResizableContainer>
```
