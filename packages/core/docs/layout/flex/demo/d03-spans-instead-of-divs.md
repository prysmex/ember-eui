---
order: 3
---

# Spans instead of divs

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