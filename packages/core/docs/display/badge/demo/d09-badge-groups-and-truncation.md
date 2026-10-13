---
order: 9
---

# Badge groups and truncation

<EuiText>

Badges, like buttons, will only every be a single line of text. This means text will not wrap, but be truncated if the badge's width reaches that of its parent's.

For this reason, badges also auto-apply the inner text of the badge to the `title` attribute of the element to provide default browser tooltips with the full badge text.

To ensure proper wrapping, truncation and spacing of multiple badges, it is advisable to wrap them in a **EuiBadgeGroup**.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiBadge, EuiBadgeGroup, EuiPanel } from '@ember-eui/core/components';

export default class BadgeGroupDemo extends Component {
  noop = () => {};

  <template>
    <EuiPanel style="max-width: 200px;">
      <EuiBadgeGroup @gutterSize="s" as |group|>
        <group.item>
          <EuiBadge>Badge with simple text being truncated</EuiBadge>
        </group.item>
        <group.item>
          <EuiBadge @iconType="clock">Badge with icon being truncated</EuiBadge>
        </group.item>
        <group.item>
          <EuiBadge @onClick={{this.noop}} @onClickAriaLabel="Click this badge to...">
            Badge with onClick being truncated
          </EuiBadge>
        </group.item>
        <group.item>
          <EuiBadge
            @iconType="cross"
            @iconSide="right"
            @iconOnClick={{this.noop}}
            @iconOnClickAriaLabel="Click this icon to..."
          >
            Badge with iconOnClick being truncated
          </EuiBadge>
        </group.item>
        <group.item>
          <EuiBadge
            @iconType="cross"
            @iconSide="right"
            @onClick={{this.noop}}
            @onClickAriaLabel="Click this badge to..."
            @iconOnClick={{this.noop}}
            @iconOnClickAriaLabel="Click this icon to..."
          >
            Badge with both onClicks being truncated
          </EuiBadge>
        </group.item>
      </EuiBadgeGroup>
    </EuiPanel>
  </template>
}
```

