---
order: 2
---

# Badge with Icon

<EuiText>
  <p>
    Badges can use icons on the left and right (default) sides.
    When using a URL for the icon make sure to pass <EuiCode>iconUseSvg</EuiCode> as <EuiCode>false</EuiCode> for the image to show properly.
  </p>
</EuiText>

```hbs template
<EuiBadge
  @iconUseSvg={{false}}
  @iconType='https://iconarchive.com/download/i103537/sensibleworld/starwars/Death-Star.ico'
  @iconSide='right'
  @color='warning'
>
  Star Wars Lore
</EuiBadge>

<EuiBadge
  @iconUseSvg={{false}}
  @iconType='https://static.thenounproject.com/png/65913-200.png'
  @iconSide='left'
  @color='hollow'
>
  Darth Vader
</EuiBadge>
<EuiBadge
  @iconUseSvg={{false}}
  @iconType='https://static.thenounproject.com/png/65913-200.png'
  @iconSide='left'
  @color='hollow'
/>
<EuiBadge @iconType='returnKey' @color='#c5c5c5' />
```
