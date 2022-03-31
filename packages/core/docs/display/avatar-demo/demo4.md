---
order: 4
---

# Icons

<EuiText>
  <p>

Icons can also be displayed instead of initials or images. When simply passing an <EuiCode>iconType</EuiCode>, it will both size and color appropriately based on the other <strong>EuiAvatar</strong> props. To customize these specifically, pass <EuiCode>iconSize</EuiCode> and <EuiCode>iconColor</EuiCode>.

If your icon has multiples or custom colors like a logo, you can keep the default <EuiCode>iconColor</EuiCode> by passing <EuiCode>null</EuiCode>. Otherwise it will get the appropriate contrast acceptable variant. Just ensure that you also are providing an accesible background color to match that of the icon's color.

  </p>
</EuiText>

```hbs template
<EuiTitle @size='xs'>
  Icon colors and sizes
</EuiTitle>
<div>
  <EuiAvatar @size='s' @name='Small Size' @iconType='managementApp' />
  <EuiAvatar @size='m' @name='Medium Size' @iconType='managementApp' />
  <EuiAvatar @size='l' @name='Large' @iconType='managementApp' />
  <EuiAvatar
    @size='xl'
    @name='Plain color'
    @color='plain'
    @iconType='managementApp'
  />
</div>

<EuiTitle @size='xs'>
  Icon colors and sizes
</EuiTitle>
<EuiSpacer />
<div>
  <EuiAvatar @name='Avatar color' @iconType='managementApp' @color='#BD10E0' />
  <EuiAvatar
    @name='Custom iconColor'
    @iconType='managementApp'
    @color='#E6F1FA'
    @iconColor='primary'
  />
  <EuiAvatar
    @name='Null iconColor'
    @iconType='managementApp'
    @iconColor={{null}}
    @color='#D3DAE6'
  />
  <EuiAvatar @name='Large iconSize' @iconType='managementApp' @iconSize='l' />
</div>
```
