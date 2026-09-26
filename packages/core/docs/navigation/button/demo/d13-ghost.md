---
order: 13
---

# Ghost buttons

<EuiText>

On dark backgrounds, `@color="ghost"` renders white buttons. `EuiButton`,
`EuiButtonEmpty` and `EuiButtonIcon` all support it.

</EuiText>

```hbs template
<div style="background: #25282f; padding: 16px; border-radius: 6px;">
  <EuiFlexGroup @gutterSize="s" @alignItems="center" @wrap={{true}} @responsive={{false}}>
    <EuiFlexItem @grow={{false}}>
      <EuiButton @color="ghost">Ghost</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiButton @color="ghost" @fill={{true}} @iconType="check">Filled</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty @color="ghost">Empty</EuiButtonEmpty>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiButtonIcon @color="ghost" @iconType="gear" aria-label="Settings" />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
```
