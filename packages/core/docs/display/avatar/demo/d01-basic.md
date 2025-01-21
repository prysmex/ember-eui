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
    @name='Random'
    @imageUrl='https://picsum.photos/64'
  />
  <EuiAvatar
    @size='m'
    @name='Random'
    @imageUrl='https://picsum.photos/64'
  />
  <EuiAvatar
    @size='l'
    @name='Random'
    @imageUrl='https://picsum.photos/64'
  />
  <EuiAvatar
    @size='xl'
    @name='Random'
    @imageUrl='https://picsum.photos/64'
  />
</div>
```
