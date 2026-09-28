---
order: 1
---

# Edit and compare

<EuiText>

Edit the text on the right: the diff below updates as you type.

</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiFormRow @label="Before">
      <EuiTextArea @value={{this.before}} @rows={{4}} {{on "input" this.setBefore}} />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="After">
      <EuiTextArea @value={{this.after}} @rows={{4}} {{on "input" this.setAfter}} />
    </EuiFormRow>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiPanel @color="subdued">
  <EuiText>
    <EuiTextDiff @beforeText={{this.before}} @afterText={{this.after}} />
  </EuiText>
</EuiPanel>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class TextDiffDemo extends Component {
  @tracked before =
    'The quick brown fox jumps over the lazy dog, then naps in the sun.';
  @tracked after =
    'The quick red fox leaps over the sleepy dog, then naps in the shade.';

  @action
  setBefore(event) {
    this.before = event.target.value;
  }

  @action
  setAfter(event) {
    this.after = event.target.value;
  }
}
```
