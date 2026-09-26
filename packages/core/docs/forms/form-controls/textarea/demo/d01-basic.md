---
order: 1
---

# Textarea

<EuiText>

Keep the value and update it on `input`, like the other fields. `@rows`
sets the visible height; the user can resize it vertically by default.

</EuiText>

```hbs template
<EuiFormRow @label="Feedback" @helpText="{{this.remaining}} characters left.">
  <EuiTextArea
    @value={{this.text}}
    @rows={{4}}
    maxlength="280"
    {{on "input" this.updateText}}
  />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class TextareaDemo extends Component {
  @tracked text = 'The new dashboard is great!';

  get remaining() {
    return 280 - this.text.length;
  }

  @action
  updateText(event) {
    this.text = event.target.value;
  }
}
```
