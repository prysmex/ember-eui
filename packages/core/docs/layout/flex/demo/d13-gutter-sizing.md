---
order: 13
---

# Gutter sizing

<EuiText>

`@gutterSize` sets the space between items: `none`, `xs`, `s`, `m`, `l` (default) or `xl`.

</EuiText>

```hbs template
<div>
  <EuiFlexGroup class="flex-demo" @gutterSize="none">
    <EuiFlexItem>None</EuiFlexItem>
    <EuiFlexItem>None</EuiFlexItem>
    <EuiFlexItem>None</EuiFlexItem>
    <EuiFlexItem>None</EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer />

  <EuiFlexGroup class="flex-demo" @gutterSize="xs">
    <EuiFlexItem>Extra small</EuiFlexItem>
    <EuiFlexItem>Extra small</EuiFlexItem>
    <EuiFlexItem>Extra small</EuiFlexItem>
    <EuiFlexItem>Extra small</EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer />

  <EuiFlexGroup class="flex-demo" @gutterSize="s">
    <EuiFlexItem>Small</EuiFlexItem>
    <EuiFlexItem>Small</EuiFlexItem>
    <EuiFlexItem>Small</EuiFlexItem>
    <EuiFlexItem>Small</EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer />

  <EuiFlexGroup class="flex-demo" @gutterSize="m">
    <EuiFlexItem>Medium</EuiFlexItem>
    <EuiFlexItem>Medium</EuiFlexItem>
    <EuiFlexItem>Medium</EuiFlexItem>
    <EuiFlexItem>Medium</EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer />

  <EuiFlexGroup class="flex-demo" @gutterSize="l">
    <EuiFlexItem>Large (default)</EuiFlexItem>
    <EuiFlexItem>Large (default)</EuiFlexItem>
    <EuiFlexItem>Large (default)</EuiFlexItem>
    <EuiFlexItem>Large (default)</EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer />

  <EuiFlexGroup class="flex-demo" @gutterSize="xl">
    <EuiFlexItem>Extra Large</EuiFlexItem>
    <EuiFlexItem>Extra Large</EuiFlexItem>
    <EuiFlexItem>Extra Large</EuiFlexItem>
    <EuiFlexItem>Extra Large</EuiFlexItem>
  </EuiFlexGroup>
</div>
```