---
order: 1
---

# Basic usage

<EuiText>

Pass an icon name as `@type`. Icons are 16px (`@size="m"`) by default and take
the color of the surrounding text, so they fit next to text without extra
styling. Find names in the gallery above.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="l" @alignItems="center" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type="bell" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type="gear" @size="l" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type="checkInCircleFilled" @size="l" @color="success" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type="logoElastic" @size="xl" @title="Elastic" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiText @size="s">
      <p><EuiIcon @type="clock" /> Updated 5 minutes ago</p>
    </EuiText>
  </EuiFlexItem>
</EuiFlexGroup>
```
