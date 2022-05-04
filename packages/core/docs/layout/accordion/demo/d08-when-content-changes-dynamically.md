---
order: 8
---

# When content changes dynamically

<EuiText>
  If an accordion’s content changes height while the accordion is open, it will
  resize dynamically.
</EuiText>
 
```hbs template
<EuiAccordion @paddingSize='s'>
  <:buttonContent>
    Click me to toggle close / open
  </:buttonContent>
  <:content>
    <EuiButton
      @size='s'
      @iconType='plusInCircleFilled'
      {{on 'click' (fn this.incrementDecreaseRows 'add')}}
    >
      Increase height to
      {{add this.counter 1}}
      items
    </EuiButton>
    <EuiButton
      @size='s'
      @iconType='minusInCircleFilled'
      {{on 'click' (fn this.incrementDecreaseRows 'sub')}}
      @isDisabled={{eq this.counter 1}}
    >
      Decrease height to
      {{sub this.counter 1}}
      items
    </EuiButton>
    <EuiSpacer />
    <EuiPanel @color='subdued'>
      <ul>
        {{#each (range 0 this.counter) as |row|}}
          <li> Row {{row}}</li>
        {{/each}}
      </ul>
    </EuiPanel>
  </:content>
</EuiAccordion>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class AccordionDemo8Component extends Component {
  @tracked counter = 1;

  @action
  incrementDecreaseRows(actionType) {
    if (actionType == 'add') {
      this.counter++;
    } else {
      this.counter--;
    }
  }
}
```
