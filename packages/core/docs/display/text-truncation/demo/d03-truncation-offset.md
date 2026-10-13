---
order: 3
---

# Truncation offset

<EuiText>

The `start` and `end` truncation types support a `@truncationOffset` argument that allows preserving a specified number of characters at either the start or end of the text. Increase or decrease the number control below to see the argument in action.

</EuiText>

```hbs template
<EuiText>
  <EuiFormRow @label='Truncation offset'>
    <EuiFieldNumber
      @compressed={{true}}
      @value={{this.truncationOffset}}
      max='30'
      {{on 'input' this.setOffset}}
    />
  </EuiFormRow>
  <EuiSpacer />
  <EuiPanel style='inline-size: 40ch; max-inline-size: 100%;'>
    <EuiTextTruncate
      @text='But the dog wasn’t lazy, it was just practicing mindfulness, so it had a greater sense of life-satisfaction than that fox with all its silly jumping.'
      @truncation='start'
      @truncationOffset={{this.truncationOffset}}
    />
    <EuiTextTruncate
      @text='And from the fox’s perspective, life was full of hoops to jump through, low-hanging fruit to jump for, and dead car batteries to jump-start.'
      @truncation='end'
      @truncationOffset={{this.truncationOffset}}
    />
  </EuiPanel>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked truncationOffset = 3;

  @action
  setOffset(event) {
    this.truncationOffset = Number(event.target.value);
  }
}
```
