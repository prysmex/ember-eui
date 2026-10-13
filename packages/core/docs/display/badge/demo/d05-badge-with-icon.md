---
order: 5
---

# Badge with Icon

<EuiText>

Badges can use icons on the left and right (default) sides.

</EuiText>

```hbs template
<div>
  <EuiBadge @color="hollow" @iconType="cross" @iconSide="right">Hollow</EuiBadge>

  <EuiBadge @iconType="check">Default</EuiBadge>

  <EuiBadge @iconType="lensApp" @color="primary">Primary with an app icon</EuiBadge>

  <EuiBadge @iconType="return" />
</div>
```
