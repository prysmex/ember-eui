# Demo

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
          @onClick={{this.punchIt}}
          @aria-label='See more details about Sketch'
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
          @onClick={{this.punchIt}}
          @aria-label='See more details about Sketch'
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
          @iconType='iInCircle'
          @size='xs'
          @onClick={{this.punchIt}}
          @aria-label='See more details about Sketch'
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
