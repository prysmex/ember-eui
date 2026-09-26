---
order: 6
---

# Selectable

<EuiText>

`@selectable` adds a "Select" toggle to the bottom of the card:
`{ onClick, isSelected, isDisabled, color }`. Clicking anywhere on the card
toggles it; keep the selected state yourself.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='l'>
  <EuiFlexItem>
    <EuiCard
      @icon='logoSketch'
      @iconSize='xxl'
      @title='Sketch'
      @description='Example of a short card description.'
      @selectable={{hash
        onClick=(fn this.selectToggle 'cardOneSelected')
        isSelected=this.cardOneSelected
      }}
    >
      <:footer>
        <EuiButtonEmpty
          @iconType='iInCircle'
          @size='xs'
          aria-label='See more details about Sketch'
          {{on 'click' this.punchIt}}
        >
          More details
        </EuiButtonEmpty>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @icon='logoGCP'
      @iconSize='xxl'
      @title='Google'
      @description='Example of a short card description.'
      @selectable={{hash
        onClick=(fn this.selectToggle 'cardTwoSelected')
        isSelected=this.cardTwoSelected
      }}
    >
      <:footer>
        <EuiButtonEmpty
          @iconType='iInCircle'
          @size='xs'
          aria-label='See more details about Sketch'
          {{on 'click' this.punchIt}}
        >
          More details
        </EuiButtonEmpty>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @icon='logoAerospike'
      @iconSize='xxl'
      @title='Not Adobe'
      @description='Example of a short card description.'
      @selectable={{hash
        onClick=(fn this.selectToggle 'cardThreeSelected')
        isSelected=this.cardThreeSelected
      }}
    >
      <:footer>
        <EuiButtonEmpty
          @size='xs'
          @iconType='iInCircle'
          aria-label='See more details about Sketch'
          {{on 'click' this.punchIt}}
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
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoCardComponent extends Component {
  @tracked cardOneSelected = true;
  @tracked cardTwoSelected = false;
  @tracked cardThreeSelected = false;
  @tracked cardFourSelected = false;

  @tracked weaponLocked = true;

  @action
  punchIt(event) {
    // keep the click from also toggling the card
    event.stopPropagation();
    alert('You punched into hyperspacer!');
  }

  @action
  selectToggle(card, event) {
    this[card] = !this[card];
    event.stopPropagation();
  }
}
```
