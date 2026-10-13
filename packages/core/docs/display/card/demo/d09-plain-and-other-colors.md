---
order: 9
---

# Plain and other colors

<EuiText>

If you need a card with no borders or shadows pass `@display="plain"`. This is a good option to avoid nested panels. Adding an interaction to the card will provide the clickable styling on hover. The `@display` argument also accepts all other **EuiPanel** colors like `'transparent'`.

For non-interactive cards, reduce or eliminate the padding as needed to suit your layout with the `@paddingSize` argument.

</EuiText>

```hbs template
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
</EuiFlexGrid>
```

```js component
import Component from '@glimmer/component';

export default class CardColorsDemo extends Component {
  noop = () => {};
}
```
