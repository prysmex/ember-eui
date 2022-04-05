---
order: 6
---

# Badge groups and truncation

<EuiText>
  <p>
Badges, like buttons, will only every be a single line of text. This means text will not wrap, but be truncated if the badge's width reaches that of its parent's.

For this reason, badges also auto-apply the inner text of the badge to the <EuiCode>title</EuiCode> attribute of the element to provide default browser tooltips with the full badge text.

To ensure proper wrapping, truncation and spacing of multiple badges, it is advisable to wrap them in a <strong>EuiBadgeGroup</strong>.

  </p>
</EuiText>

```hbs template
<EuiSpacer @hasShadow={{false}} />
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
