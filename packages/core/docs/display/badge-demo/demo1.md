# Demo

```hbs template
<EuiPanel @color='subdued'>
  <EuiTitle @size='xs'>
    Accepted color names
  </EuiTitle>
  <EuiSpacer />
  <EuiBadge @color='default'>
    default
  </EuiBadge>
  <EuiBadge @color='hollow'>
    hollow
  </EuiBadge>
  <EuiBadge @color='primary'>
    primary
  </EuiBadge>
  <EuiBadge @color='success'>
    success
  </EuiBadge>
  <EuiBadge @color='accent'>
    accent
  </EuiBadge>
  <EuiBadge @color='danger'>
    danger
  </EuiBadge>
  <EuiBadge @color='warning'>
    warning
  </EuiBadge>
  <EuiSpacer />
  <EuiTitle @size='xs'>
    Custom color examples
  </EuiTitle>

  <EuiSpacer />
  <EuiBadge @color='#DDD'>
    #DDD
  </EuiBadge>
  <EuiBadge @color='#AAA'>
    #AAA
  </EuiBadge>
  <EuiBadge @color='#666'>
    #666
  </EuiBadge>
  <EuiBadge @color='#333'>
    #333
  </EuiBadge>
  <EuiBadge @color='#BADA55'>
    #BADA55
  </EuiBadge>
  <EuiBadge @color='#FCF7BC'>
    #FCF7BC
  </EuiBadge>
  <EuiBadge @color='#FEA27F'>
    #FEA27F
  </EuiBadge>
  <EuiBadge @color='#FFA500'>
    #FFA500
  </EuiBadge>
  <EuiBadge @color='#0000FF'>
    #0000FF
  </EuiBadge>

  <EuiSpacer />
  <EuiTitle @size='xs'>
    Disabled state
  </EuiTitle>
  <EuiSpacer />
  <EuiBadge
    @iconType='arrowRight'
    @color='#f6f6f6'
    @onClick={{this.toggleDisabled}}
    @iconSide='right'
  >
    Click me to disable this guy
  </EuiBadge>
  <EuiBadge
    @isDisabled={{this.disabled}}
    @iconType={{if this.disabled 'faceSad' 'faceHappy'}}
    @color='accent'
  >
    I am
    {{if this.disabled 'disabled' 'enabled!'}}
  </EuiBadge>
  <EuiSpacer />
  <EuiText @size='xs'>
    Click on the Dot icon to turn the lightsaber on!
  </EuiText>
  <EuiBadge
    @color='#e5e5e5'
    @iconOnClick={{this.toggleLightsaber}}
    @iconType='dot'
    @iconSide='right'
  >
    0===|*|==|
  </EuiBadge>
  <EuiBadge @isDisabled={{this.lightsaberDisabled}} @color='#F83A00'>
    ----------------------------------------------------------
  </EuiBadge>
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Badge with Icon
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Badges can use icons on the left and right (default) sides.
  </p>
</EuiText>
<EuiSpacer />
<EuiPanel @color='subdued'>
  <EuiBadge
    @iconType='https://iconarchive.com/download/i103537/sensibleworld/starwars/Death-Star.ico'
    @iconSide='right'
    @color='warning'
  >
    Star Wars Lore
  </EuiBadge>

  <EuiBadge
    @iconType='https://static.thenounproject.com/png/65913-200.png'
    @iconSide='left'
    @color='hollow'
  >
    Darth Vader
  </EuiBadge>
  <EuiBadge @iconType='returnKey' @color='#c5c5c5' />
</EuiPanel>

<EuiSpacer />
<EuiTitle @size='m'>
  Badge with onClick events
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Badges can have onClick events applied to the badge itself or the icon
    within the badge. The latter option is useful for when you might use badges
    in other components (like a tag system with autocomplete where you need
    close events).
  </p>
</EuiText>
<EuiSpacer />
<EuiPanel @color='subdued'>

  <EuiBadge
    @color='primary'
    @iconType='cross'
    @iconSide='right'
    @iconOnClick={{this.clickIcon}}
    @onClick={{this.clickBadge}}
  >
    Clickable
  </EuiBadge>
  <EuiBadge @onClick={{this.clickBadge}} @iconType='check' @color='#c5c5c5'>
    Click Text Only!
  </EuiBadge>
  <EuiBadge
    @iconOnClick={{this.clickIcon}}
    @color='#c9c9c9'
    @iconType='returnKey'
  >
    Click Icon Only!
  </EuiBadge>
</EuiPanel>

<EuiSpacer />
<EuiTitle @size='m'>
  Badge for health status
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Badges can work as health status indicators in places where there are a lot
    of repeated statuses, e.g. in tables.
  </p>
</EuiText>
<EuiSpacer />

<EuiPanel @color='subdued'>

  <EuiBadge @color='success'>
    Healthy
  </EuiBadge>
  <EuiBadge @color='warning'>
    Warning
  </EuiBadge>
  <EuiBadge @color='danger'>
    Critical
  </EuiBadge>
  <EuiBadge @color='default'>
    Unknown
  </EuiBadge>
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Badge with href
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Badges can also be made to render anchor tags by passing an href.
  </p>
</EuiText>
<EuiSpacer />
<EuiPanel @color='subdued'>
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
<EuiSpacer />
<EuiTitle @size='m'>
  Beta badge type
</EuiTitle>
<EuiSpacer />

<EuiPanel @color='subdued'>
  <EuiBetaBadge @label='Beta' @title='Philly' />
  <EuiBetaBadge @label='Beta' @title='Philly' />
  <EuiBetaBadge @label='B' @title='Philly' />
  <EuiBetaBadge @label='B' @title='Philly' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' />
  <EuiSpacer @size='xs' />
  <EuiBetaBadge @label='Beta' @title='Philly' />
  <EuiBetaBadge @label='Beta' @title='Philly' />
  <EuiBetaBadge @label='B' @title='Philly' />
  <EuiBetaBadge @label='B' @title='Philly' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' />
  <EuiSpacer @size='xs' />
  <EuiBetaBadge @label='Beta' @title='Philly' />
  <EuiBetaBadge @label='Beta' @title='Philly' />
  <EuiBetaBadge @label='B' @title='Philly' />
  <EuiBetaBadge @label='B' @title='Philly' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' />
  <EuiSpacer />
  <EuiTitle @size='m'>
    Beta badges will also line up nicely with titles
    <EuiBetaBadge @label='Beta' @title='Philly' />
  </EuiTitle>
  <EuiTitle @size='xs'>
    Clickable beta badges
  </EuiTitle>
  <EuiSpacer />
  <EuiBetaBadge
    @label='Lab'
    @title='Coat'
    @iconType='beaker'
    @onClick={{this.clickBetaBadge}}
  />
  <EuiBetaBadge
    @label='Beta'
    @title='Philly'
    @href='http://www.elastic.co/subscriptions'
  />
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Beta badge type
</EuiTitle>
<EuiSpacer />
<EuiPanel @color='subdued'>
  <EuiNotificationBadge>
    1
  </EuiNotificationBadge>
  <EuiNotificationBadge @color='subdued'>
    4
  </EuiNotificationBadge>
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Badge Group
</EuiTitle>
<EuiSpacer />
<EuiPanel style='max-width: 200px;' @color='subdued'>
  <EuiBadgeGroup @gutterSize='s' as |Group|>
    <Group.item>
      <EuiBadge @href='#' @color='accent'>
        Example of a good ol' badge group item 1
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge @iconType='check' @color='primary'>
        Example of a good ol' badge group item 2
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge @iconType='check' @iconSide='right' @color='success'>
        Example of a good ol' badge group item 3
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge @onClick={{this.clickBadge}} @color='#fffeee'>
        Example of a good ol' badge group item 4
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge
        @onClick={{this.clickBadge}}
        @iconType='cross'
        @iconOnClick={{this.clickIcon}}
        @color='#e5e5e5'
      >
        Example of a good ol' badge group item 5
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge
        @onClick={{this.clickBadge}}
        @iconSide='right'
        @iconType='cross'
        @iconOnClick={{this.clickIcon}}
        @color='#f5f5f5'
      >
        Example of a good ol' badge group item 6
      </EuiBadge>
    </Group.item>
  </EuiBadgeGroup>
</EuiPanel>
<EuiSpacer />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoIconComponent extends Component {
  @tracked disabled = false;
  @tracked lightsaberDisabled = true;

  @action
  toggleDisabled() {
    this.disabled = !this.disabled;
  }

  @action
  toggleLightsaber() {
    this.lightsaberDisabled = !this.lightsaberDisabled;
  }

  @action
  clickIcon() {
    alert('ICON clicked!');
  }

  @action
  clickBadge() {
    alert('BADGE TEXT clicked!');
  }
  @action
  clickBetaBadge() {
    alert('Beta Badge clicked!');
  }
}
```
