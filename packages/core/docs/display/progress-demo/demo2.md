# Demo 2

To make a progress bar actually progressable, you should pass down the `@max` prop.

`:label` prop is used as a named block.

`@value` is the number value of the progress bar that is passed down as a HTML attribute to the `<progress />` tag.

ValueText can be and should be a `@valueText` prop and `:valueText` named block. Whenever the `@valueText` prop is passed as TRUE, that means you want the `@value` prop to be displayed atop the progress bar. When set to false or not passed at all, that means you DON'T want `@value` to be displayed OR that you are passing a custom `:valueText` named block.<br><br>

```hbs template
<EuiButton {{on "click" this.increaseValue1}}>
  Click!
</EuiButton>
<EuiSpacer @size="m" />
<EuiProgress
  @max={{100}}
  @color="primary"
  @size="l"
  @value={{this.value1}}
  @valueText={{true}}
>
  <:label>
    Click it!
  </:label>
</EuiProgress>

<EuiSpacer @size="m" />

<EuiProgress
  @max={{100}}
  @color="success"
  @size="l"
  @value={{this.value1}}
>
  <:label>
    Click it!
  </:label>
  <:valueText>
    {{this.value1Text}}
  </:valueText>
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
