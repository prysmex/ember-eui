# Demo

```hbs template
<EuiPanel @color='subdued'>
  <EuiAvatar @size='s' @name='Raphael' />
  <EuiAvatar @size='m' @name='Donatello' />
  <EuiAvatar @size='l' @name='Leonardo' @color='#BD10E0' />
  <EuiAvatar @size='xl' @name='Michelangelo' />
  <EuiSpacer />
  <EuiTitle @size='xs'>
    With image
  </EuiTitle>
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
</EuiPanel>

<EuiSpacer />
<EuiTitle @size='m'>
  Initials
</EuiTitle>
<EuiSpacer />
<EuiPanel @color='subdued'>
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
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Types
</EuiTitle>
<EuiSpacer />
<EuiPanel @color='subdued'>
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
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Icons
</EuiTitle>
<EuiSpacer />
<EuiPanel @color='subdued'>
  <EuiTitle @size='xs'>
    Icon colors and sizes
  </EuiTitle>
  <EuiAvatar @size='s' @name='Small Size' @iconType='managementApp' />
  <EuiAvatar @size='m' @name='Medium Size' @iconType='managementApp' />
  <EuiAvatar @size='l' @name='Large' @iconType='managementApp' />
  <EuiAvatar
    @size='xl'
    @name='Plain color'
    @color='plain'
    @iconType='managementApp'
  />

  <EuiTitle @size='xs'>
    Icon colors and sizes
  </EuiTitle>
  <EuiSpacer />
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
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Disabled
</EuiTitle>
<EuiSpacer />
<EuiPanel @color='subdued'>
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
</EuiPanel>
```
