---
order: 5
---

# Selectable

<EuiText>

When you have a list of cards that can be selected but **do not navigate anywhere**, you can add the `@selectable` argument. It is an object (`{ onClick, isSelected, isDisabled, color }`) that configures the select button seen below, and passing `isSelected=true` will alter the styles of the card and button to look selected.

</EuiText>
<EuiSpacer />
<EuiCallOut @color="success" @size="s" @title="Extra links in a selectable card">
  <p>When providing an extra link to more details or such, be sure to stop event propagation from also selecting the card.</p>
</EuiCallOut>
<EuiSpacer />

```hbs template
<EuiFlexGroup @gutterSize="l">
  <EuiFlexItem>
    <EuiCard
      @icon="logoSketch"
      @iconSize="xxl"
      @title="Sketch"
      @description="Example of a short card description."
      @selectable={{hash onClick=this.card1Clicked isSelected=this.card1Selected}}
    >
      <:footer>
        <EuiButtonEmpty
          @iconType="info"
          @size="xs"
          aria-label="See more details about Sketch"
          {{on "click" this.detailsClicked}}
        >
          More details
        </EuiButtonEmpty>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @icon="logoGCP"
      @iconSize="xxl"
      @title="Google"
      @description="Example of a longer card description. See how the footers stay lined up."
      @selectable={{hash onClick=this.card2Clicked isSelected=this.card2Selected}}
    >
      <:footer>
        <EuiButtonEmpty
          @iconType="info"
          @size="xs"
          aria-label="See more details about Google"
          {{on "click" this.detailsClicked}}
        >
          More details
        </EuiButtonEmpty>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @icon="logoAerospike"
      @iconSize="xxl"
      @title="Not Adobe"
      @description="Example of a short card description."
      @selectable={{hash onClick=this.noop isDisabled=true}}
    >
      <:footer>
        <EuiButtonEmpty
          @iconType="info"
          @size="xs"
          aria-label="See more details about Not Adobe"
          {{on "click" this.detailsClicked}}
        >
          More details
        </EuiButtonEmpty>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CardSelectableDemo extends Component {
  @tracked card1Selected = true;
  @tracked card2Selected = false;

  noop = () => {};

  @action card1Clicked() {
    this.card1Selected = !this.card1Selected;
  }

  @action card2Clicked() {
    this.card2Selected = !this.card2Selected;
  }

  @action detailsClicked(event) {
    event.stopPropagation();
  }
}
```
