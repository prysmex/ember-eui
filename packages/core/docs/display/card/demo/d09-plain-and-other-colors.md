---
order: 9
---

# Plain and other colors

<EuiText>

If you need a card with no borders or shadows pass `@display="plain"`. This is a good option to avoid nested panels. Adding an interaction to the card will provide the clickable styling on hover. The `@display` argument also accepts all other **EuiPanel** colors like `'transparent'`. Use `@hasBorder` to draw a border instead of a shadow.

For non-interactive cards, reduce or eliminate the padding as needed to suit your layout with the `@paddingSize` argument.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCard, EuiFlexGrid, EuiFlexItem } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

export default class CardColorsDemo extends Component {
  noop = () => {};

  <template>
    <EuiFlexGrid @columns={{2}}>
      <EuiFlexItem>
        <EuiCard
          @layout="horizontal"
          @icon="logoLogging"
          @iconSize="xl"
          @onClick={{this.noop}}
          @title="Plain"
          @display="plain"
          @description="This one still has a solid background color."
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiCard
          @icon="logoLogging"
          @iconSize="xl"
          @title="Subdued"
          @display="subdued"
          @description="This one has a subdued background color."
          @onClick={{this.noop}}
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiCard
          @layout="horizontal"
          @icon="logoLogging"
          @iconSize="xl"
          @title="Transparent"
          @display="transparent"
          @description="This one doesn't have a background color anymore."
          @betaBadgeProps={{hash
            label="Beta"
            tooltipContent="This module is not GA. Please help us by reporting any bugs."
          }}
          @onClick={{this.noop}}
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiCard
          @icon="logoLogging"
          @iconSize="xl"
          @title="Bordered"
          @display="plain"
          @hasBorder={{true}}
          @description="This one has a plain background color and border."
          @onClick={{this.noop}}
        />
      </EuiFlexItem>
    </EuiFlexGrid>
  </template>
}
```

