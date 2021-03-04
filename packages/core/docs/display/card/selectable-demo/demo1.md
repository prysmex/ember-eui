# Demo

```hbs template

<EuiSpacer @size="xl" />
<EuiTitle @size="m">
  Selectable
</EuiTitle>
<EuiSpacer @size="s" />
<div
  class="euiFlexGroup euiFlexGroup--directionRow euiFlexGroup--responsive euiFlexGroup--gutterLarge"
>
  <div class="euiFlexItem">
    <EuiCard
      @title="E-11 Blaster Rifle"
      @titleSize="s"
      @titleElement="h3"
      @description="Manufactured by BlasTech Industries"
      @image="https://vignette.wikia.nocookie.net/starwars/images/2/20/E-11_blaster_rifle_DICE.png/revision/latest/scale-to-width-down/500?cb=20151106030234"
      @selectable={{hash
        color="primary"
        onClick=(fn this.selectToggle "cardOneSelected")
        isSelected=this.cardOneSelected
      }}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCard
      @title="A280 Blaster Rifle"
      @titleSize="s"
      @titleElement="h3"
      @description="Manufactured by BlasTech Industries"
      @image="https://vignette.wikia.nocookie.net/starwars/images/c/c1/A280_blaster_rifle.jpg/revision/latest/scale-to-width-down/499?cb=20061203115750"
      @selectable={{hash
        onClick=(fn this.selectToggle "cardTwoSelected")
        isSelected=this.cardTwoSelected
      }}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCard
      @title="E-10 Blaster Rifle"
      @titleSize="s"
      @titleElement="h3"
      @description="Manufactured by BlasTech Industries"
      @image="https://vignette.wikia.nocookie.net/starwars/images/6/6f/E-10.png/revision/latest/scale-to-width-down/500?cb=20181125220049"
      @selectable={{hash
        onClick=(fn this.selectToggle "cardThreeSelected")
        isSelected=this.cardThreeSelected
      }}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCard
      @title="E-5C Heavy Blaster Rifle"
      @titleSize="s"
      @titleElement="h3"
      @description="Manufactured by BlasTech Industries"
      @image="https://vignette.wikia.nocookie.net/starwars/images/b/ba/E-5C_BF2.png/revision/latest/scale-to-width-down/499?cb=20180310060911"
      @selectable={{hash
        onClick=(fn this.selectToggle "cardFourSelected")
        isSelected=this.cardFourSelected
        isDisabled=this.weaponLocked
      }}
    />
  </div>
</div>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoCardComponent extends Component {
  @tracked cardOneSelected = false;
  @tracked cardTwoSelected = false;
  @tracked cardThreeSelected = false;
  @tracked cardFourSelected = false;

  @tracked weaponLocked = true;

  @action
  punchIt() {
    alert('You punched into hyperspacer!');
  }

  @action
  selectToggle(card, event) {
    this[card] = !this[card];
    event.stopPropagation();
  }
}
```
