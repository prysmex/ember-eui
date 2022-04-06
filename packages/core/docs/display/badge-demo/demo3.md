---
order: 3
---

# Badge with onClick events

<EuiText>
  <p>

Badges can have <EuiCode>onClick</EuiCode> events applied to the badge itself or the icon within the badge. The latter option is useful for when you might use badges in other components (like a tag system with autocomplete where you need close events).

  </p>
</EuiText>

```hbs template
<EuiPanel @hasShadow={{false}}>

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
