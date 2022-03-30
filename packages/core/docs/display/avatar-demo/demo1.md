---
order: 1
---

<EuiText>
  <p>

The <strong>EuiAvatar</strong> component typically creates a user icon. It will accept <EuiCode>name</EuiCode> (required) and <EuiCode>image</EuiCode> props and will configure the display and accessibility as needed. By default, the background colors come from the set of colors used for visualizations. Otherwise you can pass a hex value to the <EuiCode>color</EuiCode> prop.

  </p>
</EuiText>

```hbs template
<div>
  <EuiAvatar @size='s' @name='Raphael' />
  <EuiAvatar @size='m' @name='Donatello' />
  <EuiAvatar @size='l' @name='Leonardo' @color='#BD10E0' />
  <EuiAvatar @size='xl' @name='Michelangelo' />
</div>
<EuiSpacer />
<EuiTitle @size='xs'>
  With image
</EuiTitle>
<div>
  <EuiAvatar
    @size='s'
    @name='Cat'
    @imageUrl='https://source.unsplash.com/64x64/?cat'
  />
  <EuiAvatar
    @size='m'
    @name='Cat'
    @imageUrl='https://source.unsplash.com/64x64/?cat'
  />
  <EuiAvatar
    @size='l'
    @name='Cat'
    @imageUrl='https://source.unsplash.com/64x64/?cat'
  />
  <EuiAvatar
    @size='xl'
    @name='Cat'
    @imageUrl='https://source.unsplash.com/64x64/?cat'
  />
</div>
```
