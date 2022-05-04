---
order: 1
---

# Flex group is for a single row layout

```hbs template
  <EuiFlexGroup class="flex-demo">
    <EuiFlexItem>Content grid item</EuiFlexItem>
    <EuiFlexItem>
      <p>Another content grid item</p>
      <EuiSpacer />
      <p>
        Note how both of these are the same width and height despite having
        different content?
      </p>
    </EuiFlexItem>
  </EuiFlexGroup>
```