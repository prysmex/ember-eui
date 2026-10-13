---
order: 8
---

# Badge with href

<EuiText>

Badges can also be made to render anchor tags by passing an `@href`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiBadge, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

export default class BadgeHrefDemo extends Component {
  noop = () => {};

  <template>
    <EuiFlexGroup @wrap={{true}} @responsive={{false}} @gutterSize="xs">
      <EuiFlexItem @grow={{false}}>
        <EuiBadge @color="#BADA55" @href="#/display/badge">
          badge as an anchor
        </EuiBadge>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiBadge @color="hollow" @href="#/display/badge" @target="blank">
          anchor with target specified
        </EuiBadge>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiBadge
          @color="accent"
          @href="#/display/badge"
          @iconType="bolt"
          @iconSide="right"
          @iconOnClick={{this.noop}}
          @iconOnClickAriaLabel="Example of onClick event for icon within the anchor"
        >
          anchor with an icon and iconOnClick
        </EuiBadge>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiBadge @color="success" @href="#/display/badge" @isDisabled={{true}}>
          disabled anchor badge
        </EuiBadge>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

