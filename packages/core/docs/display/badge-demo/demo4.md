---
order: 4
---

# Badge for health status

<EuiText>
  <p>
Badges can work as health status indicators in places where there are a lot
of repeated statuses, e.g. in tables.
  </p>
</EuiText>

```hbs template
<EuiPanel>
  <EuiBadge @color='success'>
    Healthy
  </EuiBadge>
  <EuiBadge @color='warning'>
    Warning
  </EuiBadge>
  <EuiBadge @color='danger'>
    Critical
  </EuiBadge>
  <EuiBadge @color='default'>
    Unknown
  </EuiBadge>
</EuiPanel>
```
