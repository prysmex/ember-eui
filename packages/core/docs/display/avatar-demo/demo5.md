---
order: 5
---

# Disabled

<EuiText>
  <p>

While <strong>EuiAvatar</strong> doesn't accept any interactive behaviors itself, you can create a visually presented disabled avatar by adding <EuiCode>isDisabled</EuiCode> when placed within a disabled element.

  </p>
</EuiText>

```hbs template
<div>
  <EuiAvatar
    @size='m'
    @type='space'
    @isDisabled={{true}}
    @name='Leonardo Dude'
    @initialsLength={{1}}
  />
  <EuiAvatar @size='m' @isDisabled={{true}} @name='Two Words' />
  <EuiAvatar
    @size='m'
    @isDisabled={{true}}
    @name='Cat'
    @imageUrl='https://source.unsplash.com/64x64/?cat'
  />
  <EuiAvatar
    @size='m'
    @isDisabled={{true}}
    @name='Medium Size'
    @iconType='managementApp'
  />
</div>
```
