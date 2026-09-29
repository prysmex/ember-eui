---
order: 1
---

# Horizontal

<EuiText>

Drag the separator, or focus it with <kbd>Tab</kbd> and use the left and
right arrow keys.

</EuiText>

```hbs template
<EuiResizableContainer style="height: 200px;" as |c|>
  <c.Panel @initialSize={{35}} @minSize="20%">
    <EuiText @size="s">
      <p><strong>Sidebar.</strong> At least 20% wide.</p>
    </EuiText>
  </c.Panel>
  <c.Button />
  <c.Panel @initialSize={{65}} @minSize="200px">
    <EuiText @size="s">
      <p><strong>Content.</strong> At least 200px wide. Long text wraps as
        the panel narrows, and scrolls when it does not fit.</p>
    </EuiText>
  </c.Panel>
</EuiResizableContainer>
```
