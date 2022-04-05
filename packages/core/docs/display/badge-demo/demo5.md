---
order: 5
---

# Badge with href

<EuiText>
  <p>
Badges can also be made to render anchor tags by passing an href.
  </p>
</EuiText>

```hbs template
<EuiPanel @hasShadow={{false}}>
  <EuiBadge
    @href='https://starwars.fandom.com/wiki/Main_Page'
    @iconType='https://iconarchive.com/download/i103537/sensibleworld/starwars/Death-Star.ico'
    @iconSide='right'
    @color='warning'
  >
    Star Wars Lore
  </EuiBadge>

  <EuiBadge
    @href='https://starwars.fandom.com/wiki/Main_Page'
    @iconType='https://static.thenounproject.com/png/65913-200.png'
    @iconSide='left'
    @color='hollow'
  >
    Darth Vader
  </EuiBadge>
</EuiPanel>
```
