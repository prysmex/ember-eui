---
order: 3
---

# Spans instead of divs

<EuiText>

Inside elements that only accept inline content (e.g. a `<button>`), pass `@tagName="span"` to both the group and its items.

</EuiText>

```hbs template
<button>
  <EuiFlexGroup class="flex-demo" @tagName="span">
    <EuiFlexItem @tagName="span">
      These items are within a button
    </EuiFlexItem>

    <EuiFlexItem @tagName="span">
      So they all specify component=&ldquo;span&rdquo;
    </EuiFlexItem>
  </EuiFlexGroup>
</button>
```