---
order: 7
---

# Badge for health status

<EuiText>

Badges can work as health status indicators in places where there are a lot of repeated statuses, e.g. in tables.

</EuiText>

```hbs template
<EuiFlexGroup @wrap={{true}} @responsive={{false}} @gutterSize="xs">
  <EuiFlexItem @grow={{false}}>
    <EuiBadge @color="success">Healthy</EuiBadge>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiBadge @color="warning">Warning</EuiBadge>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiBadge @color="danger">Critical</EuiBadge>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiBadge @color="default">Unknown</EuiBadge>
  </EuiFlexItem>
</EuiFlexGroup>
```
