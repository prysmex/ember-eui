---
order: 2
---

# Progress with values

<EuiText>
<p>Once the <EuiCode @language="text">max</EuiCode> and <EuiCode @language="text">value</EuiCode> props are set, it will act as a determinate progress bar. This is rendered using an HTML5 <EuiCode @language="text">progress</EuiCode> tag.</p>

</EuiText>

```hbs template
<EuiButton {{on 'click' this.increaseValue1}}>
  Click!
</EuiButton>
<EuiSpacer @size='m' />
<EuiProgress
  @max={{100}}
  @color='primary'
  @size='l'
  @value={{this.value1}}
  @valueText={{true}}
>
  <:label>
    Click it!
  </:label>
</EuiProgress>
```

```js component
// should be Controller
import Component from '@ember/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { computed } from '@ember/object';

export default class DemoProgressComponent extends Component {
  @tracked value1 = 0;

  @computed('value1')
  get value1Text() {
    if (this.value1 == 0) {
      return 'Progress me!';
    } else if (this.value1 < 40) {
      return 'Keep at it!';
    } else if (this.value1 >= 40 && this.value1 < 70) {
      return 'Keep going!! Grind it!';
    } else if (this.value1 >= 70 && this.value1 < 100) {
      return 'Almost there!!';
    } else if (this.value1 == 100) {
      return 'Nailed it!';
    }
  }

  @action
  increaseValue1() {
    if (this.value1 < 100) {
      this.value1 += 10;
    }
  }
}
```
