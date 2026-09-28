---
order: 1
---

# Beacon

<EuiText>

Next to a new feature, and in a bigger size. `@size` is the diameter of
the center dot in px.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="center" @gutterSize="xl" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiFlexGroup @alignItems="center" @gutterSize="s" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty @iconType="visLine">Dashboards</EuiButtonEmpty>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiBeacon />
      </EuiFlexItem>
    </EuiFlexGroup>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiBeacon @size={{30}} />
  </EuiFlexItem>
</EuiFlexGroup>
```
