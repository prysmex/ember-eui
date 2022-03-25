---
order: 3
---

# Types

<EuiText>
  <p>

The avatar <EuiCode>type</EuiCode>, which primarily defines the shape, is keyworded and can be <EuiCode>"user"</EuiCode> (default) or <EuiCode>"space"</EuiCode> (for workspaces).

  </p>
</EuiText>

```hbs template
<EuiAvatar @size='s' @type='space' @name='Kibana' @initialsLength={{2}} />
<EuiAvatar
  @size='m'
  @type='space'
  @name='Leonardo Dude'
  @initialsLength={{1}}
/>
<EuiAvatar @size='l' @type='space' @name='Not provided' @initials='?' />
<EuiAvatar
  @size='xl'
  @type='space'
  @name='Engineering Space'
  @initials='En'
  @initialsLength={{2}}
/>
```
