---
order: 2
---

# Badge with Icon

<EuiText>
  <p>

Badges can use icons on the left and right (default) sides.

  </p>
</EuiText>

```hbs template
<EuiPanel @hasShadow={{false}}>
  <EuiBadge
    @iconType='https://iconarchive.com/download/i103537/sensibleworld/starwars/Death-Star.ico'
    @iconSide='right'
    @color='warning'
  >
    Star Wars Lore
  </EuiBadge>

  <EuiBadge
    @iconType='https://static.thenounproject.com/png/65913-200.png'
    @iconSide='left'
    @color='hollow'
  >
    Darth Vader
  </EuiBadge>
  <EuiBadge @iconType='returnKey' @color='#c5c5c5' />
</EuiPanel>
```
