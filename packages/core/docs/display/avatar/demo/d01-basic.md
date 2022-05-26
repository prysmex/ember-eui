---
order: 1
---

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
