---
order: 2
---

# Initials

<EuiText>
  <p>

The initials displayed in the avatar try to be smart based on the name prop. If the name contains spaces, it will display the first character of each word, <strong>always maxing out at 2 characters.</strong> You can customize this by passing a combination of <EuiCode>initialsLength</EuiCode> and/or <EuiCode>initials</EuiCode> props. However, the avatar will still always max out at 2 characters.

  </p>
</EuiText>

```hbs template
<EuiTitle @size='xs'>
  Single vs multi-word
</EuiTitle>
<EuiSpacer />
<EuiAvatar @size='m' @name='Single' />
<EuiAvatar @size='m' @name='Two Words' />
<EuiAvatar @size='m' @name='More Than Two Words' />
<EuiAvatar @size='m' @name='lowercase words' />
<EuiSpacer />
<EuiTitle @size='xs'>
  Custom
</EuiTitle>
<EuiSpacer />
<EuiAvatar @size='m' @name='Kibana' @initialsLength={{2}} />
<EuiAvatar @size='m' @name='Leonardo Dude' @initialsLength={{1}} />
<EuiAvatar @size='m' @name='Not provided' @initials='?' />
<EuiAvatar
  @size='m'
  @name='Engineering Space'
  @initials='En'
  @initialsLength={{2}}
/>
```
