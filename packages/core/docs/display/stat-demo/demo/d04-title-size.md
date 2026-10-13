---
order: 4
---

# Title size

<EuiText>

`@title` uses the **EuiTitle** component and thus uses the same sizing values (applied via the `@titleSize` argument). Although all **EuiTitle** sizes are available, suggested sizes include `'l' | 'm' | 's' | 'xs' | 'xxs' | 'xxxs'`. By default, the size is set to large `'l'`. The `@description` label cannot be re-sized via component arguments.

</EuiText>

```hbs template
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat @title="1,000,000" @description="Large size" @titleSize="l" />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title="1,000,000" @description="Medium size" @titleSize="m" />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title="1,000,000" @description="Small size" @titleSize="s" />
    </EuiFlexItem>
  </EuiFlexGroup>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat @title="1,000,000" @description="Extra small size" @titleSize="xs" />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title="1,000,000" @description="Extra extra small size" @titleSize="xxs" />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiStat @title="1,000,000" @description="Extra extra extra small size" @titleSize="xxxs" />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```
