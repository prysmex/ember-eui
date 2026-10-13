---
order: 4
---

# Beta badge

<EuiText>

If the card links to or references a module that is not GA (beta, lab, etc), you can add a `betaBadgeProps.label` and `betaBadgeProps.tooltipContent` to the card and it will properly create and position an **EuiBetaBadge**. If you want to change the title of the tooltip, supply a `betaBadgeProps.title`.

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
            label="Basic"
            title="Monitoring"
            tooltipContent="This module requires a Basic license."
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
          @description="Disabled cards keep their beta badge."
          @betaBadgeProps={{hash
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

