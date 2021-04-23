---
order: 1
---

# Demo

```hbs template
<EuiTitle>
  Text:
  {{this.text1}}
</EuiTitle>
<EuiTextArea @value={{this.text1}} {{on "input" (pick "target.value" (set this "text1"))}} />
<EuiSpacer />
<EuiTitle>
  Text:
  {{this.text2}}
</EuiTitle>
<EuiTextArea
  @value={{this.text2}}
  @rows={{10}}
  @resize="both"
  @isInvalid={{true}}
  {{on "input" (pick "target.value" (set this "text2"))}}
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked text1 = '';
  @tracked text2 = '';
}
```
