---
order: 1
---

<EuiText>
  <p>

<strong>EuiBadges</strong> are used to focus on important bits of information. Although they will automatically space themselves if you use them in a repetitive fashion it is good form to wrap them using a <strong>EuiBadgeGroup</strong> so that they will wrap when width is constrained (as seen below).

  </p>
</EuiText>

```hbs template
<EuiPanel>
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
