# Demo

```hbs template
<EuiBadge
  @href="https://starwars.fandom.com/wiki/Main_Page"
  @iconType="https://iconarchive.com/download/i103537/sensibleworld/starwars/Death-Star.ico"
  @iconSide="right"
>
  Star Wars Lore
</EuiBadge>
<EuiBadge
  @href="https://starwars.fandom.com/wiki/Main_Page"
  @iconType="https://static.thenounproject.com/png/65913-200.png"
  @iconSide="right"
  @color="default"
>
  Darth Vader
</EuiBadge>
<EuiSpacer />
<EuiBadge @href="#" @color="accent">
  Hello
</EuiBadge>
<EuiBadge @color="danger">
  Danger!
</EuiBadge>
<EuiBadge @onClick={{this.clickBadge}} @color="#000fff">
  Custom color
</EuiBadge>
<EuiBadge
  @color="primary"
  @iconType="cross"
  @iconSide="right"
  @iconOnClick={{this.clickIcon}}
  @onClick={{this.clickBadge}}
>
  Clickable
</EuiBadge>
<EuiBadge @onClick={{this.clickBadge}} @iconType="check" @color="#c5c5c5">
  Click Text Only!
</EuiBadge>
<EuiBadge
  @iconOnClick={{this.clickIcon}}
  @color="#c9c9c9"
  @iconType="returnKey"
>
  Click Icon Only!
</EuiBadge>
<EuiTitle @size="s">
  Icon left or right
</EuiTitle>
<EuiBadge @iconType="check" @color="#c5c5c5">
  On your left!
</EuiBadge>
<EuiBadge @iconType="check" @iconSide="right">
  On your right!
</EuiBadge>
<EuiTitle @size="s">
  Icon Only
</EuiTitle>
<EuiBadge @iconType="returnKey" @color="#c5c5c5" />
<EuiBadge @iconType="check" />
<EuiSpacer />
<EuiTitle @size="s">
  Disabled
</EuiTitle>
<EuiBadge
  @iconType="arrowRight"
  @color="#f6f6f6"
  @onClick={{this.toggleDisabled}}
  @iconSide="right"
>
  Click me to disable this guy
</EuiBadge>
<EuiBadge
  @isDisabled={{this.disabled}}
  @iconType={{if this.disabled "faceSad" "faceHappy"}}
  @color="accent"
>
  I am
  {{if this.disabled "disabled" "enabled!"}}
</EuiBadge>
<EuiSpacer @size="s" />
<EuiText @size="xs">
  Click on the Dot icon to turn the lightsaber on!
</EuiText>
<EuiBadge
  @color="#e5e5e5"
  @iconOnClick={{this.toggleLightsaber}}
  @iconType="dot"
  @iconSide="right"
>
  0===|*|==|
</EuiBadge>
<EuiBadge @isDisabled={{this.lightsaberDisabled}} @color="#F83A00">
  ----------------------------------------------------------
</EuiBadge>
<EuiSpacer />
<EuiTitle @tagName="h2" @size="m">
  Notification Badge
</EuiTitle>
<EuiNotificationBadge>
  1
</EuiNotificationBadge>
<EuiNotificationBadge>
  2
</EuiNotificationBadge>
<EuiNotificationBadge>
  3
</EuiNotificationBadge>
<EuiNotificationBadge @color="subdued">
  4
</EuiNotificationBadge>
<EuiNotificationBadge @size="m">
  5
</EuiNotificationBadge>
<EuiSpacer />
<EuiTitle @size="m">
  Beta Badge
  <EuiBetaBadge @label="Beta" @title="Philly" />
</EuiTitle>
<EuiBetaBadge @label="Pill" @title="Philly" />
<EuiBetaBadge @label="Lab" @title="Coat" @iconType="beaker" />
<EuiSpacer />
<EuiTitle @tagName="h2" @size="m">
  Badge Group
</EuiTitle>
<EuiPanel style="max-width: 200px;">
  <EuiBadgeGroup @gutterSize="s" as |Group|>
    <Group.item>
      <EuiBadge @href="#" @color="accent">
        Example of a good ol' badge group item 1
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge @iconType="check" @color="primary">
        Example of a good ol' badge group item 2
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge @iconType="check" @iconSide="right" @color="secondary">
        Example of a good ol' badge group item 3
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge @onClick={{this.clickBadge}} @color="#fffeee">
        Example of a good ol' badge group item 4
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge
        @onClick={{this.clickBadge}}
        @iconType="cross"
        @iconOnClick={{this.clickIcon}}
        @color="#e5e5e5"
      >
        Example of a good ol' badge group item 5
      </EuiBadge>
    </Group.item>
    <Group.item>
      <EuiBadge
        @onClick={{this.clickBadge}}
        @iconSide="right"
        @iconType="cross"
        @iconOnClick={{this.clickIcon}}
        @color="#f5f5f5"
      >
        Example of a good ol' badge group item 6
      </EuiBadge>
    </Group.item>
  </EuiBadgeGroup>
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
}
```
