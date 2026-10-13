---
order: 4
---

# Beta badge

<EuiText>

If the card links to or references a module that is not GA (beta, lab, etc), you can add a `betaBadgeProps.label` and `betaBadgeProps.tooltipContent` to the card and it will properly create and position an **EuiBetaBadge**. If you want to change the title of the tooltip, supply a `betaBadgeProps.title`. The badge's `color` (`hollow`, `accent`, `subdued` or `warning`), `href`, `target`, `onClick` and the other **EuiBetaBadge** arguments can be passed the same way. A disabled card greys its badge, unless the badge is a link or button, or has its own `color`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCard, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

export default class CardBetaDemo extends Component {
  noop = () => {};

  <template>
    <EuiFlexGroup @gutterSize="l">
      <EuiFlexItem>
        <EuiCard
          @icon="dashboardApp"
          @iconSize="xxl"
          @title="Dashboards"
          @description="Example of a card's description. Stick to one or two sentences."
          @onClick={{this.noop}}
          @betaBadgeProps={{hash
            label="Beta"
            tooltipContent="This module is not GA. Please help us by reporting any bugs."
          }}
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiCard
          @icon="monitoringApp"
          @iconSize="xxl"
          @title="Monitoring"
          @description="Example of a card's description. Stick to one or two sentences."
          @betaBadgeProps={{hash
            label="Accent"
            color="accent"
            tooltipContent="You can change the badge color using betaBadgeProps.color."
          }}
          @onClick={{this.noop}}
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiCard
          @icon="lensApp"
          @iconSize="xxl"
          @title="Lens"
          @isDisabled={{true}}
          @description="Disabled cards can have active links using EuiBetaBadge."
          @betaBadgeProps={{hash
            href="http://www.elastic.co/subscriptions"
            target="_blank"
            label="Basic"
            tooltipContent="Disabled cards with still clickable badges will stay hollow."
          }}
          @onClick={{this.noop}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

