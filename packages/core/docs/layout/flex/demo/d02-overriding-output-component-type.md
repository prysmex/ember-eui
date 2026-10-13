---
order: 2
---

# Overriding output component type

<EuiText>

Upstream accepts a `component` prop on the group, grid or item. In Ember EUI `@tagName` does the same on `EuiFlexItem` and `EuiFlexGrid` (any tag name) and on `EuiFlexGroup` (`div` or `span`).

This allows you to use semantic tags with flex layouts, or to obey rules around nesting block elements within inline elements. Here the group and its items are `span`s so they are valid inside a paragraph.

</EuiText>

```hbs template
<p>
  <EuiFlexGroup class="flex-demo" @tagName="span">
    <EuiFlexItem @tagName="span">
      These items are nested within a paragraph tag
    </EuiFlexItem>

    <EuiFlexItem @tagName="span">
      So they use inline span tags to avoid HTML validation issues
    </EuiFlexItem>
  </EuiFlexGroup>
</p>
```
